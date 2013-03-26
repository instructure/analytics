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

    def assignment_scope
      # would be nicer if this could be
      # @course.assignments.active.scoped(:order => ...), but the
      # Course#assignments association has a built in order that can't be
      # overridden.
      @assignment_scope ||= @course.shard.activate do
        Assignment.active.
          where(:context_id => @course, :context_type => 'Course').
          includes(:versions). # Optimizes AssignmentOverrideApplicator
          order("assignments.due_at, assignments.id")
      end
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
