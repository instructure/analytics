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
      @available ||= if @enrollments.nil?
        slaved{ enrollment_scope.count > 0 }
      else
        enrollments.present?
      end
    end

    def enrollments
      @enrollments ||= slaved do
        rows = enrollment_scope.find(:all, :order => User.sortable_name_order_by_clause('users'))
        Enrollment.send(:preload_associations, rows, [
          {:user => {:pseudonyms => :account}},
          :course_section,
          {:course => :enrollment_term}
        ])
        rows
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

    def students
      @students ||= enrollments.map{ |e| e.user }.uniq
    end

    def student_ids
      @student_ids ||= students.map(&:id)
    end

    include Analytics::Participation
    include Analytics::Assignments

    def extended_assignment_data(assignment, submissions)
      breakdown = { :on_time => 0, :late => 0, :missing => 0 }
      submitted_ats = submissions.map{ |s| submission_date(assignment, s) }.compact
      total = students.size.to_f

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
      @student_summaries ||= slaved do
        summaries = {}

        # set up default summary per student
        student_ids.each do |student_id|
          summaries[student_id] = {
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

        # count page views and participations by student
        page_view_scope.find(:all, :select => "user_id, COUNT(*) AS ct", :group => "user_id").each do |row|
          summaries[row.user_id.to_i][:page_views] = row.ct.to_i
        end

        page_view_scope.find(:all, :select => "user_id, COUNT(DISTINCT(asset_user_access_id, url)) AS ct",
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
        submission_scope(assignments).each do |submission|
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

        summaries
      end
    end

  private

    def enrollment_scope
      @enrollment_scope ||= @course.enrollments_visible_to(@current_user, true).
        scoped(:conditions => { 'enrollments.workflow_state' => ['active', 'completed'] })
    end

    def page_view_scope
      @page_view_scope ||= @course.page_views.
        scoped(:conditions => { :user_id => student_ids })
    end

    def submission_scope(assignments)
      @submission_scope ||= @course.shard.activate do
        Submission.
          scoped(:select => "assignment_id, score, user_id, submission_type, submitted_at, graded_at, updated_at, workflow_state").
          scoped(:conditions => { :assignment_id => assignments.map(&:id) }).
          scoped(:conditions => { :user_id => student_ids })
      end
    end
  end
end
