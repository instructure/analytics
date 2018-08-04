#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

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
      cache(:available) { enrollment_scope.exists? }
    end

    def enrollments
      @enrollments ||= slaved do
        rows = enrollment_scope.to_a
        ActiveRecord::Associations::Preloader.new.preload(rows, [ :course_section, {:course => :enrollment_term} ])
        rows
      end
    end

    def start_date
      # TODO the javascript will break if this comes back nil, so we need a
      # sensible default. using "now" for the time being, but there's gotta be
      # something better
      slaved(:cache_as => :start_date) do
        [
            enrollment_scope.minimum(:start_at),
            @course.sections_visible_to(@current_user).minimum(:start_at),
            @course.start_at,
            @course.enrollment_term.start_at,
            @course.enrollment_term.enrollment_dates_overrides.where(enrollment_type: 'StudentEnrollment').minimum(:start_at),
        ].compact.min ||
            @course.sections_visible_to(@current_user).minimum(:created_at) ||
            @course.created_at ||
            Time.zone.now
      end
    end

    def end_date
      # TODO ditto. "now" makes more sense this time, but it could also make
      # sense to go past "now" if the course has assignments due in the future,
      # for instance.
      slaved(:cache_as => :end_date) do
        [
            enrollment_scope.maximum(:end_at),
            @course.sections_visible_to(@current_user).maximum(:end_at),
            @course.conclude_at,
            @course.enrollment_term.end_at,
            @course.enrollment_term.enrollment_dates_overrides.where(enrollment_type: 'StudentEnrollment').maximum(:end_at),
        ].compact.max || Time.zone.now
      end
    end

    def students
      slaved(:cache_as => :students) { student_scope.order_by_sortable_name.to_a }
    end

    def student_ids
      slaved(:cache_as => :student_ids) do
        # id of any user with an enrollment, order unimportant
        enrollment_scope.distinct.pluck(:user_id)
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
        :multiple_due_dates => vdd.multiple_due_dates_apply_to?(@current_user),
        :non_digital_submission => assignment.non_digital_submission?
      )
    end

    def extended_assignment_data(assignment, submissions)
      { tardiness_breakdown: tardiness_breakdowns[:assignments][assignment.id].as_hash_scaled }
    end

    def student_summaries(opts = {})
      sort_column = opts[:sort_column]
      student_ids = opts[:student_ids]

      # course global counts (by student) and maxima
      # we have to select the entire course here, because we need to calculate
      # the max over the whole course not just the students the pagination is
      # returning.
      page_view_counts = page_views_by_student

      # wrap up the students for pagination, and then tell it how to sort them
      # and format them
      collection = Analytics::StudentCollection.new(
        student_ids ?
          student_scope.where(users: {id: student_ids}) :
          student_scope
      )
      collection.sort_by(sort_column, :page_view_counts => page_view_counts)

      student_summaries = StudentSummaries.new(self, page_view_counts)
      collection.format do |student|
        student_summaries.for(student).as_hash
      end

      collection
    end

    def page_views_by_student
      slaved(:cache_as => :page_views_by_student) do
        PageView.counters_by_context_for_users(@course, student_ids)
      end
    end

    def page_view_analysis(page_view_counts)
      slaved(:cache_as => :page_view_analysis) do
        PageViewAnalysis.new( page_view_counts ).hash
      end
    end

    def allow_student_details?
      @course.grants_any_right?(@current_user, :manage_grades, :view_all_grades)
    end

    def cache_prefix
      [@course, Digest::MD5.hexdigest(enrollment_scope.to_sql)]
    end

    def enrollment_scope
      @enrollment_scope ||= @course.apply_enrollment_visibility(@course.all_student_enrollments, @current_user).
        where(:enrollments => { :workflow_state => ['active', 'completed'] })
    end

    def submissions(assignments, student_ids=self.student_ids)
      @course.shard.activate{ submission_scope(assignments, student_ids).to_a }
    end

    def submission_scope(assignments, student_ids=self.student_ids)
      ::Analytics::Course.submission_scope_for(assignments).where(user_id: student_ids)
    end

    def self.submission_scope_for(assignments)
      Submission.
        select(Analytics::Assignments::SUBMISSION_COLUMNS_SELECT).
        where(:assignment_id => assignments)
    end

    def student_scope
      @student_scope ||= begin
        # any user with an enrollment, ordered by name
        subselect = enrollment_scope.select([:id, :user_id]).to_sql
        User.shard(@course.shard).
          select("DISTINCT (users.id), users.*, scores.current_score as computed_current_score").
          joins(@course.send(:sanitize_sql, [<<-SQL, true]))
            INNER JOIN (#{subselect}) AS enrollments ON enrollments.user_id = users.id
            LEFT JOIN #{Score.quoted_table_name} scores ON
              scores.enrollment_id = enrollments.id AND
              scores.course_score = ? AND
              scores.workflow_state <> 'deleted'
            SQL
      end
    end

    def raw_assignments
      cache_array = [:raw_assignments]
      cache_array << @current_user if differentiated_assignments_applies?
      slaved(:cache_as => cache_array) do
        assignment_scope.to_a
      end
    end

    def tardiness_breakdowns
      @course.shard.activate do
        cache_array = [:tardiness_breakdowns]
        cache_array << @current_user if differentiated_assignments_applies?
        @tardiness_breakdowns ||= slaved(:cache_as => cache_array) do
          # initialize breakdown tallies
          breakdowns = {
            assignments: Hash[raw_assignments.map{ |a| [a.id, TardinessBreakdown.new] }],
            students:    Hash[student_ids.map{  |s_id| [s_id, TardinessBreakdown.new] }]
          }

          # load submissions and index them by (assignment, student) tuple
          submissions = FakeSubmission.from_scope(submission_scope(raw_assignments))
          submissions = submissions.index_by{ |s| [s.assignment_id, s.user_id] }

          # tally each submission (or lack thereof) into the columns and rows of
          # the breakdown
          raw_assignments.each do |assignment|
            student_ids.each do |student_id|
              submission = submissions[[assignment.id, student_id]]
              submission.assignment = assignment if submission
              assignment_submission = AssignmentSubmission.new(assignment, submission)
              breakdowns[:assignments][assignment.id].tally!(assignment_submission)
              breakdowns[:students][student_id].tally!(assignment_submission)
            end
          end

          # done
          breakdowns
        end
      end
    end
  end
end
