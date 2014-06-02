require_dependency 'analytics/assignment_submission'

module Analytics
  class Course < Analytics::Base
    def self.available_for?(current_user, course)
      new(current_user, course).available?
    end

    def initialize(current_user, course)
      super(current_user)
      @course = course
    end

    def available?
      # not slaved because it's pretty lightweight and we don't want it to
      # depend on the slave being present
      cache(:available) { enrollment_scope.first.present? }
    end

    def enrollments
      @enrollments ||= slaved do
        rows = enrollment_scope.all
        Enrollment.send(:preload_associations, rows, [ :course_section, {:course => :enrollment_term} ])
        rows
      end
    end

    def start_date
      # TODO the javascript will break if this comes back nil, so we need a
      # sensible default. using "now" for the time being, but there's gotta be
      # something better
      slaved(:cache_as => :start_date) do
        enrollments.map{ |e| e.effective_start_at }.compact.min || Time.zone.now
      end
    end

    def end_date
      # TODO ditto. "now" makes more sense this time, but it could also make
      # sense to go past "now" if the course has assignments due in the future,
      # for instance.
      slaved(:cache_as => :end_date) do
        enrollments.map{ |e| e.effective_end_at }.compact.max || Time.zone.now
      end
    end

    def students
      slaved(:cache_as => :students) { student_scope.order_by_sortable_name.all }
    end

    def student_ids
      slaved(:cache_as => :student_ids) do
        # id of any user with an enrollment, order unimportant
        enrollment_scope.select(:user_id).uniq.map{ |e| e.user_id }
      end
    end

    def participation
      slaved(:cache_as => :participation) do
        @course.page_views_rollups.
          select("date, SUM(views) AS views, SUM(participations) AS participations").
          group(:date).
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    include Analytics::Assignments

    def overridden_assignment(assignment, user)
      assignment.overridden_for(user)
    end

    # Overriding this from Assignments to account for Variable Due Dates
    def basic_assignment_data(assignment, submissions=nil)
      vdd = overridden_assignment( assignment, @current_user )
      super.merge(
        :due_at => vdd.due_at,
        :multiple_due_dates => vdd.multiple_due_dates_apply_to?(@current_user)
      )
    end

    def extended_assignment_data(assignment, submissions)
      { tardiness_breakdown: tardiness_breakdowns[:assignments][assignment.id].as_hash_scaled }
    end

    def student_summaries(sort_column=nil)
      # course global counts (by student) and maxima
      # we have to select the entire course here, because we need to calculate
      # the max over the whole course not just the students the pagination is
      # returning.
      page_view_counts = self.page_views_by_student
      analysis = PageViewAnalysis.new( page_view_counts )

      # wrap up the students for pagination, and then tell it how to sort them
      # and format them
      collection = Analytics::StudentCollection.new(student_scope)
      collection.sort_by(sort_column, :page_view_counts => page_view_counts)
      collection.format do |student|
        {
          :id => student.id,
          :page_views => page_view_counts[student.id][:page_views],
          :max_page_views => analysis.max_page_views,
          :participations => page_view_counts[student.id][:participations],
          :max_participations => analysis.max_participations,
          :tardiness_breakdown => tardiness_breakdowns[:students][student.id].as_hash
        }
      end

      collection
    end

    def page_views_by_student
      slaved(:cache_as => :page_views_by_student) do
        PageView.counters_by_context_for_users(@course, student_ids)
      end
    end

    def allow_student_details?
      @course.grants_any_right?(@current_user, :manage_grades, :view_all_grades)
    end

    def cache_prefix
      [@course, Digest::MD5.hexdigest(enrollment_scope.to_sql)]
    end

    def enrollment_scope
      @enrollment_scope ||= @course.enrollments_visible_to(@current_user, :include_priors => true).
        where(:enrollments => { :workflow_state => ['active', 'completed'] })
    end

    def submissions(assignments, student_ids=self.student_ids)
      @course.shard.activate do
        ::Analytics::Course.submission_scope_for(assignments).where(:user_id => student_ids).all
      end
    end

    def self.submission_scope_for(assignments)
      Submission.
        select(Analytics::Assignments::SUBMISSION_COLUMNS_SELECT).
        where(:assignment_id => assignments)
    end

    def student_scope
      @student_scope ||= begin
        # any user with an enrollment, ordered by name
        subselect = enrollment_scope.select([:user_id, :computed_current_score]).uniq.to_sql
        User.
          select("users.*, enrollments.computed_current_score").
          joins("INNER JOIN (#{subselect}) AS enrollments ON enrollments.user_id=users.id")
      end
    end

    def raw_assignments
      slaved(:cache_as => :raw_assignments) do
        assignment_scope.all
      end
    end

    def tardiness_breakdowns
      @tardiness_breakdowns ||= slaved(:cache_as => :tardiness_breakdowns) do
        breakdowns = { assignments: {}, students: {} }
        course_submissions = submissions(raw_assignments)

        # Tally By Assignments
        assignment_submissions = course_submissions.group_by(&:assignment_id)
        raw_assignments.each do |assignment|
          breakdowns[:assignments][assignment.id] ||= TardinessBreakdown.new
          if assignment_submissions[assignment.id]
            submissions = assignment_submissions[assignment.id].index_by(&:user_id)
          end
          submissions ||= {}

          student_ids.each do |student_id|
            assignment_submission = AssignmentSubmission.new(assignment, submissions[student_id])
            breakdowns[:assignments][assignment.id].tally!(assignment_submission)
          end
        end

        # Tally By Students
        student_submissions = course_submissions.group_by(&:user_id)
        student_ids.each do |student_id|
          breakdowns[:students][student_id] ||= TardinessBreakdown.new
          if student_submissions[student_id]
            submissions = student_submissions[student_id].index_by(&:assignment_id)
          end
          submissions ||= {}

          raw_assignments.each do |assignment|
            assignment_submission = AssignmentSubmission.new(assignment, submissions[assignment.id])
            breakdowns[:students][student_id].tally!(assignment_submission)
          end
        end

        breakdowns
      end
    end
  end
end
