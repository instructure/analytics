module Analytics
  class StudentInCourse
    def self.available_for?(current_user, session, course, student)
      new(current_user, session, course, student).available?
    end

    def initialize(current_user, session, course, student)
      @current_user = current_user
      @session = session
      @course = course
      @student = student
    end

    def available?
      !enrollments.empty?
    end

    def self.available_enrollments(user, course)
      slaved do
        course.enrollments_visible_to(user, true).
          scoped(:include => :user).
          find(:all, :conditions => { 'enrollments.workflow_state' => ['active', 'completed'] },
               :order => User.sortable_name_order_by_clause('users')).
          # only first enrollment per student, but still want the enrollment
          # returned, not the student
          group_by{ |enrollment| enrollment.user }.
          map{ |student,enrollments| enrollments.first }
      end
    end

    def enrollments
      @enrollments ||= slaved do
        @course.enrollments_visible_to(@current_user, true).
          find(:all, :conditions => {
            :workflow_state => ['active', 'completed'],
            :user_id => @student.id
          })
      end
    end

    def start_date
      # TODO the javascript will break if this comes back nil, so we need a
      # sensible default. using "now" for the time being, but there's gotta be
      # something better
      @start_date ||= slaved do
        enrollments.map{ |e| e.effective_start_at }.compact.min || Time.zone.now
      end
    end

    def end_date
      # TODO ditto. "now" makes more sense this time, but it could also make
      # sense to go past "now" if the course has assignments due in the future,
      # for instance.
      @end_date ||= slaved do
        enrollments.map{ |e| e.effective_end_at }.compact.max || Time.zone.now
      end
    end

    def page_views
      @page_views ||= slaved do
        page_views = {}
        page_view_scope.find(:all,
          :select => "DATE(created_at) AS day, controller, COUNT(*) AS ct",
          :group => "DATE(created_at), controller").each do |row|
          day = row.day
          action = controller_to_action(row.controller)
          count = row.ct.to_i
          page_views[day] ||= {}
          page_views[day][action] ||= 0
          page_views[day][action] += count
        end
        page_views
      end
    end

    def participations
      @participations ||= slaved do
        foo = {}
        page_view_scope.find(:all,
          :select => "page_views.created_at, page_views.url, asset_user_accesses.asset_code, asset_user_accesses.asset_category",
          :include => :asset_user_access,
          :conditions => "page_views.participated AND page_views.asset_user_access_id IS NOT NULL").map do |participation|

          foo[participation.asset_user_access_id] ||= {}
          foo[participation.asset_user_access_id][participation.url] ||= {
            :created_at => participation.created_at,
            :url => participation.url,
            :asset_code => participation.asset_user_access.asset_code,
            :asset_category => participation.asset_user_access.asset_category
          }
        end
        foo.map{ |_,bin| bin.map{ |_,hash| hash } }.flatten
      end
    end

    def assignments
      @assignments ||= slaved do
        assignments = assignment_scope.find(:all)
        submissions = Submission.scoped(:select => "assignment_id, score, user_id, submission_type, submitted_at, updated_at").
          find(:all, :conditions => { :assignment_id => assignments.map(&:id) })
        submissions = submissions.group_by{ |s| s.assignment_id }

        student_view = !@course.grants_rights?(@current_user, @session, :manage_grades, :view_all_grades).values.any?

        assignments.map do |assignment|
          muted = student_view && assignment.muted?

          hash = {
            :assignment_id => assignment.id,
            :title => assignment.title,
            :unlock_at => assignment.unlock_at,
            :due_at => assignment.due_at,
            :points_possible => assignment.points_possible,
            :muted => muted
          }

          scores = Stats::Counter.new
          (submissions[assignment.id] || []).each do |submission|
            scores << submission.score if submission.score
            if @student.id == submission.user_id
              hash[:submission] = {
                :score => muted ? nil : submission.score,
                :submitted_at => submission.submitted_at
              }
            end
          end

          if muted
            hash
          else
            hash.merge(score_stats_to_hash(scores))
          end
        end
      end
    end

    def messages
      # count up the messages from those conversations authored by the student
      # or by an instructor, binned by day and whether it was the student or an
      # instructor that sent it
      @messages ||= slaved do
        messages = {}
        unless shared_conversation_ids.empty?
          ConversationMessage.
            scoped(:conditions => { :conversation_id => shared_conversation_ids }).
            scoped(:conditions => { :author_id => [@student, *instructors].map(&:id) }).
            scoped(:select => "DATE(created_at) AS day, author_id=#{@student.id} AS student, COUNT(*) AS ct",
                   :group => "DATE(created_at), author_id").each do |row|

            day = row.day
            type = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(row.student) ?
              :studentMessages :
              :instructorMessages
            count = row.ct.to_i

            messages[day] ||= {}
            messages[day][type] = count
          end
        end
        messages
      end
    end

  private

    def self.slaved
      ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) { yield }
    end

    def slaved
      self.class.slaved{ yield }
    end

    def page_view_scope
      @page_view_scope ||= PageView.
        scoped(:conditions => "page_views.summarized IS NULL").
        scoped(:conditions => { :context_type => 'Course', :context_id => @course.id, :user_id => @student.id })
    end

    def assignment_scope
      @assignment_scope ||= Assignment.active.scoped(
        :conditions => { :context_type => 'Course', :context_id => @course.id },
        :order => "assignments.due_at, assignments.id")
    end

    def section_ids
      @section_ids ||= enrollments.map(&:course_section_id).compact.uniq
    end

    def instructors
      @instructors ||= @course.instructors.restrict_to_sections(section_ids)
    end

    def student_conversation_ids
      # conversations related to this course in which the student has a hook
      @student_conversation_ids ||= ConversationParticipant.
        tagged("course_#{@course.id}").
        scoped(:conditions => { :user_id => @student.id }).
        find(:all, :select => 'DISTINCT conversation_id').
        map{ |cp| cp.conversation_id }
    end

    def shared_conversation_ids
      # subset of student conversations in which a course instructor also has a
      # hook
      return {} if student_conversation_ids.empty?
      @shared_conversation_ids ||= ConversationParticipant.
        scoped(:conditions => { :user_id => instructors.map(&:id) }).
        scoped(:conditions => { :conversation_id => student_conversation_ids }).
        find(:all, :select => 'DISTINCT conversation_id').
        map{ |cp| cp.conversation_id }
    end

    def score_stats_to_hash(stats, include_histogram=false)
      quartiles = stats.quartiles
      result = {
        :max_score => stats.max,
        :min_score => stats.min,
        :first_quartile => quartiles[0],
        :median => quartiles[1],
        :third_quartile => quartiles[2]
      }
      result[:histogram] = stats.histogram if include_histogram
      result
    end

    CONTROLLER_TO_ACTION = {
      :assignments         => :assignments,
      :courses             => :general,
      :quizzes             => :quizzes,
      :wiki_pages          => :pages,
      :gradebooks          => :grades,
      :submissions         => :assignments,
      :discussion_topics   => :discussions,
      :files               => :files,
      :context_modules     => :modules,
      :announcements       => :announcements,
      :collaborations      => :collaborations,
      :conferences         => :conferences,
      :groups              => :groups,
      :question_banks      => :quizzes,
      :gradebook2          => :grades,
      :wiki_page_revisions => :pages,
      :folders             => :files,
      :grading_standards   => :grades,
      :discussion_entries  => :discussions,
      :assignment_groups   => :assignments,
      :quiz_questions      => :quizzes,
      :gradebook_uploads   => :grades
    }

    def controller_to_action(controller)
      return CONTROLLER_TO_ACTION[controller.downcase.to_sym] || :other
    end
  end
end
