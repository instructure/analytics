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
      # not slaved or cached because it's pretty lightweight, we don't want
      # it to depend on the slave being present, and the result depends on
      # @current_user
      enrollment_scope.first
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

    include Analytics::Assignments

    def page_views
      slaved(:cache_as => :page_views) do
        # convert non-string keys from time objects to iso8601 strings since we
        # don't want to use Time#to_s on the keys in Hash#to_json
        buckets = {}
        PageView.counters_by_context_and_hour(@course, @student).each do |bucket,count|
          bucket = bucket.is_a?(String) ? bucket : bucket.in_time_zone.iso8601
          buckets[bucket] = count
        end
        buckets
      end
    end

    def participations
      slaved(:cache_as => :participations) do
        PageView.participations_for_context(@course, @student)
      end
    end

    def messages
      # count up the messages from those conversations authored by the student
      # or by an instructor, binned by day and whether it was the student or an
      # instructor that sent it
      slaved(:cache_as => :messages) do
        messages = {}
        unless shared_conversation_ids.empty?
          # TODO sharding
          ConversationMessage.
            where(:conversation_id => shared_conversation_ids).
            where(:author_id => [@student, *instructors]).
            select("DATE(created_at) AS day, author_id=#{@student.id} AS student, COUNT(*) AS ct").
            group("DATE(created_at), author_id").each do |row|

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

    def my_submission(submissions)
      submissions.detect{ |s| s.user_id == @student.id }
    end

    # Overriding this from Assignments to account for Variable Due Dates
    def basic_assignment_data(assignment)
      super.merge( :due_at => assignment.overridden_for(@student).due_at )
    end

    def extended_assignment_data(assignment, submissions)
      if s = my_submission(submissions)
        asd = assignment_submission_date(assignment, @student, s)
        return {
          :submission => {
            :score => muted(assignment) ? nil : s.score,
            :submitted_at => asd.submission_date
          }
        }
      else
        return {}
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
        where(:workflow_state => ['active', 'completed'], :user_id => @student)
    end

    def submissions(assignments)
      @course.shard.activate do
        Submission.
          select([:assignment_id, :score, :user_id, :submission_type, :submitted_at, :graded_at, :updated_at, :workflow_state]).
          where(:assignment_id => assignments).
          all
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
        where(:user_id => @student).
        select(:conversation_id).
        uniq.
        map(&:conversation_id)
    end

    def shared_conversation_ids
      # subset of student conversations in which a course instructor also has a
      # hook
      return {} if student_conversation_ids.empty?
      # TODO: sharding
      @shared_conversation_ids ||= ConversationParticipant.
        where(:user_id => instructors).
        where(:conversation_id => student_conversation_ids).
        select(:conversation_id).
        uniq.
        map(&:conversation_id)
    end
  end
end
