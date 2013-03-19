module Analytics
  module Assignments
    # required of host: submissions(assignments)

    def assignments
      slaved(:cache_as => [:assignments, allow_student_details?]) do
        assignments = assignment_scope.all
        submissions = submissions(assignments).group_by{ |s| s.assignment_id }
        assignments.map do |assignment|
          assignment_data(assignment, submissions[assignment.id])
        end
      end
    end

    def assignment_rollups
      slaved(:cache_as => :assignment_rollups) do
        assignments = assignment_scope.all
        @course.shard.activate do
          rollup_scope = Analytics::Assignments.assignment_rollup_scope_for(assignments)
          rollup_scope.map{|r| r.data }
        end
      end
    end

    def assignment_rollups_for(section_ids)
      slaved(:cache_as => [:assignment_rollups_for, section_ids]) do
        assignments = assignment_scope.all

        @course.shard.activate do
          rollup_scope = Analytics::Assignments.assignment_rollup_scope_for(assignments, section_ids)
          rollup_scope.group_by(&:assignment_id).map do |assignment_id, rollups|
            Rollups::AssignmentRollupAggregate.new(rollups).data
          end
        end
      end
    end

    def assignment_scope
      @assignment_scope ||= ::Analytics::Assignments.assignment_scope_for(@course)
    end

    def self.assignment_scope_for(this_course)
      this_course.shard.activate do
        this_course.assignments.active.
          includes(:versions). # Optimizes AssignmentOverrideApplicator
          reorder("assignments.due_at, assignments.id")
      end
    end

    def self.assignment_rollup_scope_for(assignments, section_ids = nil)
      AssignmentRollup.
        where(:assignment_id => assignments, :course_section_id => section_ids).
        order(:due_at, :assignment_id)
    end

    def assignment_data(assignment, submissions)
      submissions ||= []

      hash = basic_assignment_data(assignment).
        merge(:muted => muted(assignment))

      unless muted(assignment) || suppressed_due_to_few_submissions(submissions) || suppressed_due_to_course_setting
        scores = Stats::Counter.new
        (submissions || []).each do |submission|
          scores << submission.score if submission.score
        end
        quartiles = scores.quartiles

        hash.merge!(
          :max_score => scores.max,
          :min_score => scores.min,
          :first_quartile => quartiles[0],
          :median => quartiles[1],
          :third_quartile => quartiles[2]
        )
      end

      if self.respond_to?(:extended_assignment_data)
        hash.merge!(extended_assignment_data(assignment, submissions))
      end

      hash
    end

    def basic_assignment_data(assignment)
      {
        :assignment_id => assignment.id,
        :title => assignment.title,
        :unlock_at => assignment.unlock_at,
        :points_possible => assignment.points_possible,
        :multiple_due_dates => false # can be overridden in submodules
      }
    end

    # Mostly for test stubs
    def overridden_assignment(assignment, user)
      assignment.overridden_for(user)
    end

    # Mostly for test stubs
    def assignment_submission_date(assignment, user, submission)
      AssignmentSubmissionDate.new(assignment, user, submission)
    end

    def muted(assignment)
      !allow_student_details? && assignment.muted?
    end

    def suppressed_due_to_few_submissions(submissions)
      !allow_student_details? && submissions.size < 5
    end

    def suppressed_due_to_course_setting
      !allow_student_details? && @course.settings[:hide_distribution_graphs]
    end
  end
end
