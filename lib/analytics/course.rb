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
      slaved(:cache_as => :available) { enrollment_scope.count > 0 }
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
      @students ||= slaved do
        # any user with an enrollment, ordered by name
        subselect = enrollment_scope.scoped(:select => 'DISTINCT user_id, computed_current_score').construct_finder_sql({})
        User.scoped(
          :select => "users.*, enrollments.computed_current_score",
          :joins => "INNER JOIN (#{subselect}) AS enrollments ON enrollments.user_id=users.id").order_by_sortable_name
      end
    end

    def student_ids
      @student_ids ||= slaved do
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

    def student_summaries
      slaved(:cache_as => :student_summaries) do
        students = self.students.paginate(:page => 1, :per_page => 50)
        summaries = {}

        # set up default summary per student
        students.each do |student|
          summaries[student.id] = {
            :id => student.id,
            :page_views => 0,
            :participations => 0,
            :tardiness_breakdown => {
              :total => 0,
              :on_time => 0,
              :late => 0,
              :missing => 0
            }
          }
        end
        student_ids = students.map(&:id)

        # count page views and participations by student
        page_view_scope(student_ids).find(:all, :select => "user_id, COUNT(*) AS ct", :group => "user_id").each do |row|
          summaries[row.user_id.to_i][:page_views] = row.ct.to_i
        end

        page_view_scope(student_ids).find(:all, :select => "user_id, COUNT(DISTINCT(asset_user_access_id, url)) AS ct",
          :conditions => "participated AND asset_user_access_id IS NOT NULL", :group => "user_id").map do |row|
          summaries[row.user_id.to_i][:participations] = row.ct.to_i
        end

        # reverse index to get already-queried-assignment given id
        assignments = assignment_scope.all
        assignments_by_id = {}
        assignments.each do |assignment|
          assignments_by_id[assignment.id] = assignment
        end

        # assume each due assignment is missing as the baseline 
        due_assignment_count = assignments.select{ |a| a.due_at && a.due_at <= Time.zone.now }.size
        student_ids.each do |student_id|
          summaries[student_id][:tardiness_breakdown][:total] = assignments.size
          summaries[student_id][:tardiness_breakdown][:missing] = due_assignment_count
        end

        # for each submission...
        submission_scope(assignments, student_ids).each do |submission|
          assignment = assignments_by_id[submission.assignment_id]
          if submitted_at = submission_date(assignment, submission)
            breakdown = summaries[submission.user_id][:tardiness_breakdown]
            due_at = assignment.due_at
            if due_at && due_at <= Time.zone.now
              # shift "missing" to either "late" or "on time"
              breakdown[:missing] -= 1
              breakdown[submitted_at <= due_at ? :on_time : :late] += 1
            else
              # add new "on time" (that was never considered "missing")
              breakdown[:on_time] += 1
            end
          end
        end

        # unpack hash in the order given by students
        students.map{ |student| summaries[student.id] }
      end
    end

    def allow_student_details?
      @course.grants_rights?(@current_user, @session, :manage_grades, :view_all_grades).values.any?
    end

  private

    def cache_prefix
      @course
    end

    def enrollment_scope
      @enrollment_scope ||= @course.enrollments_visible_to(@current_user, true).
        scoped(:conditions => { 'enrollments.workflow_state' => ['active', 'completed'] })
    end

    def page_view_scope(student_ids=self.student_ids)
      @page_view_scope ||= @course.page_views.
        scoped(:conditions => { :user_id => student_ids })
    end

    def submission_scope(assignments, student_ids=self.student_ids)
      @submission_scope ||= @course.shard.activate do
        Submission.
          scoped(:select => "assignment_id, score, user_id, submission_type, submitted_at, graded_at, updated_at, workflow_state").
          scoped(:conditions => { :assignment_id => assignments.map(&:id) }).
          scoped(:conditions => { :user_id => student_ids })
      end
    end
  end
end
