module Analytics
  class StudentInCourse < Analytics::Base
    def self.available_for?(current_user, session, course, student)
      new(current_user, session, course, student).available?
    end

    def initialize(current_user, session, course, student)
      super(current_user, session)
      @course = course
      @student = student
    end

    def available?
      enrollment.present?
    end

    def enrollment
      cache(:enrollment) do
        # not slaved because it's pretty lightweight and we don't want it to
        # depend on the slave being present
        enrollment_scope.first
      end
    end

    # just parrots back @student, but sets the computed_current_score from the
    # enrollment on the student, for parity with Analytics::Course.students
    def student
      unless @student.read_attribute(:computed_current_score)
        @student.write_attribute(:computed_current_score, enrollment.computed_current_score)
      end
      @student
    end

    def start_date
      # TODO the javascript will break if this comes back nil, so we need a
      # sensible default. using "now" for the time being, but there's gotta be
      # something better
      slaved(:cache_as => :start_date) do
        enrollment.effective_start_at || Time.zone.now
      end
    end

    def end_date
      # TODO ditto. "now" makes more sense this time, but it could also make
      # sense to go past "now" if the course has assignments due in the future,
      # for instance.
      slaved(:cache_as => :end_date) do
        enrollment.effective_end_at || Time.zone.now
      end
    end

    include Analytics::Participation
    include Analytics::Assignments

    def messages
      # count up the messages from those conversations authored by the student
      # or by an instructor, binned by day and whether it was the student or an
      # instructor that sent it
      slaved(:cache_as => :messages) do
        messages = {}
        unless shared_conversation_ids.empty?
          # TODO sharding
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

    def extended_assignment_data(assignment, submissions)
      if submission = submissions.detect{ |s| s.user_id == @student.id }
        return :submission => {
          :score => muted(assignment) ? nil : submission.score,
          :submitted_at => submission_date(assignment, submission)
        }
      else
        {}
      end
    end

    def allow_student_details?
      @course.grants_rights?(@current_user, @session, :manage_grades, :view_all_grades).values.any?
    end

  private

    def cache_prefix
      [@course, @student]
    end

    def enrollment_scope
      @enrollment_scope ||= @course.enrollments_visible_to(@current_user, :include_priors => true).
        scoped(:conditions => {
          :workflow_state => ['active', 'completed'],
          :user_id => @student.id
        })
    end

    def page_view_scope
      @page_view_scope ||= @course.page_views.
        scoped(:conditions => { :user_id => @student.id })
    end

    def submission_scope(assignments)
      @submission_scope ||= @course.shard.activate do
        Submission.
          scoped(:select => "assignment_id, score, user_id, submission_type, submitted_at, graded_at, updated_at, workflow_state").
          scoped(:conditions => { :assignment_id => assignments.map(&:id) })
      end
    end

    def instructors
      @instructors ||= @course.instructors.restrict_to_sections([enrollment.course_section_id])
    end

    def student_conversation_ids
      # conversations related to this course in which the student has a hook
      # TODO: sharding
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
      # TODO: sharding
      @shared_conversation_ids ||= ConversationParticipant.
        scoped(:conditions => { :user_id => instructors.map(&:id) }).
        scoped(:conditions => { :conversation_id => student_conversation_ids }).
        find(:all, :select => 'DISTINCT conversation_id').
        map{ |cp| cp.conversation_id }
    end
  end
end
