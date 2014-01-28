module Analytics
  module Assignments
    # required of host: submissions(assignments)

    SUBMISSION_COLUMNS_SELECT = [:id, :assignment_id, :score, :user_id, :submission_type,
            :submitted_at, :grade, :graded_at, :updated_at, :workflow_state, :cached_due_date]

    def assignments
      slaved(:cache_as => [:assignments, allow_student_details?]) do
        assignments = assignment_scope.all
        submissions = submissions(assignments).group_by{ |s| s.assignment_id }
        assignments.map do |assignment|
          assignment_data(assignment, submissions[assignment.id])
        end
      end
    end

    def assignment_rollups_for(section_ids)
      assignments = assignment_scope.all

      @course.shard.activate do
        assignments.map do |assignment|
          # cache at this level, so that we cache for all sections and then
          # pick out the relevant sections from the cache below
          rollups = slaved(:cache_as => [:assignment_rollups, assignment]) do
            AssignmentRollup.build(@course, assignment)
          end
          rollups = rollups.values_at(*section_ids).compact.reject { |r| r.total_submissions.zero? }
          Rollups::AssignmentRollupAggregate.new(rollups).data
        end.compact
      end
    end

    def assignment_scope
      @assignment_scope ||= ::Analytics::Assignments.assignment_scope_for(@course)
    end

    def self.assignment_scope_for(this_course)
      this_course.shard.activate do
        scope = this_course.assignments.published if this_course.feature_enabled?(:draft_state)
        scope ||= this_course.assignments.active

        scope.includes(:versions). # Optimizes AssignmentOverrideApplicator
              reorder("assignments.due_at, assignments.id")
      end
    end

    def assignment_data(assignment, submissions)
      submissions ||= []

      hash = basic_assignment_data(assignment, submissions).
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

    def basic_assignment_data(assignment, submissions=nil)
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

    def muted(assignment)
      !allow_student_details? && assignment.muted?
    end

    def suppressed_due_to_few_submissions(submissions)
      # Need to make sure the submissions are actually submitted.
      !allow_student_details? && submissions.count { |submission|
        submission.has_submission? || submission.graded?
      } < 5
    end

    def suppressed_due_to_course_setting
      !allow_student_details? && @course.settings[:hide_distribution_graphs]
    end
  end
end
