module Analytics
  class Course < Analytics::Base
    def self.available_for?(current_user, session, course)
      new(current_user, session, course).available?
    end

    def initialize(current_user, session, course)
      super(current_user, session)
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
        enrollment_scope.scoped(:select => 'DISTINCT user_id').map{ |e| e.user_id }
      end
    end

    def participation
      slaved(:cache_as => :participation) do
        @course.page_views_rollups.
          scoped(:select => "date, sum(views) as views, sum(participations) as participations", :group => "date").
          map{ |rollup| rollup.as_json[:page_views_rollup] }
      end
    end

    include Analytics::Assignments

    def extended_assignment_data(assignment, submissions)
      breakdown = { :on_time => 0, :late => 0, :missing => 0 }
      submitted_ats = submissions.map{ |s| submission_date(assignment, s) }.compact
      total = student_ids.size.to_f

      if assignment.due_at && assignment.due_at <= Time.zone.now
        breakdown[:on_time] = submitted_ats.select{ |s| s <= assignment.due_at }.size / total
        breakdown[:late] = submitted_ats.select{ |s| s > assignment.due_at }.size / total
        breakdown[:missing] = 1 - breakdown[:on_time] - breakdown[:late]
      else
        breakdown[:on_time] = submitted_ats.size / total
      end

      { :tardiness_breakdown => breakdown }
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
          :tardiness_breakdown => tardiness_breakdown(student)
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
      @course.grants_rights?(@current_user, @session, :manage_grades, :view_all_grades).values.any?
    end

  private

    def cache_prefix
      [@course, Digest::MD5.hexdigest(enrollment_scope.construct_finder_sql({}))]
    end

    def enrollment_scope
      @enrollment_scope ||= @course.enrollments_visible_to(@current_user, :include_priors => true).
        scoped(:conditions => { 'enrollments.workflow_state' => ['active', 'completed'] })
    end

    def submissions(assignments, student_ids=self.student_ids)
      @course.shard.activate do
        Submission.
          scoped(:select => "assignment_id, score, user_id, submission_type, submitted_at, graded_at, updated_at, workflow_state").
          scoped(:conditions => { :assignment_id => assignments.map(&:id) }).
          scoped(:conditions => { :user_id => student_ids }).
          all
      end
    end

    def student_scope
      @student_scope ||= begin
        # any user with an enrollment, ordered by name
        subselect = enrollment_scope.scoped(:select => 'DISTINCT user_id, computed_current_score').construct_finder_sql({})
        User.scoped(
          :select => "users.*, enrollments.computed_current_score",
          :joins => "INNER JOIN (#{subselect}) AS enrollments ON enrollments.user_id=users.id")
      end
    end

    def raw_assignments
      slaved(:cache_as => :raw_assignments) do
        assignment_scope.all
      end
    end

    def tardiness_breakdown(student)
      slaved(:cache_as => [:tardiness_breakdown, student]) do
        # reverse index to get already-queried-assignment given id
        assignments = raw_assignments
        assignments_by_id = {}
        assignments.each{ |assignment| assignments_by_id[assignment.id] = assignment }

        # assume each due assignment is missing as the baseline
        breakdown = {
          :total => assignments.size,
          :missing => assignments.select(&:overdue?).size,
          :on_time => 0,
          :late => 0
        }

        # for each submission...
        submissions(assignments, [student.id]).each do |submission|
          assignment = assignments_by_id[submission.assignment_id]
          if submitted_at = submission_date(assignment, submission)
            if assignment.overdue?
              # shift "missing" to either "late" or "on time"
              breakdown[:missing] -= 1
              breakdown[submitted_at > assignment.due_at ? :late : :on_time] += 1
            else
              # add new "on time" (that was never considered "missing")
              breakdown[:on_time] += 1
            end
          end
        end

        # done
        breakdown
      end
    end
  end
end
