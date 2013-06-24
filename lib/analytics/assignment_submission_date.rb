module Analytics
  class AssignmentSubmissionDate
    attr_reader :assignment, :user, :submission

    def initialize(assignment, user, submission=nil)
      @assignment, @user, @submission =
       assignment,  user,  submission
      raise "user != submission.user" if submission && submission.user != user
    end

    # Returns the best-effort submission date
    def submission_date
      submitted_at || graded_varied_due_date || graded_date
    end

    # Returns the most lenient due date for the student
    def due_date
      overridden_assignment.due_at
    end

  protected

    # Make it easy to stub assignment.overridden_for out for tests
    def overridden_assignment_unmemoized
      @assignment.overridden_for(@user)
    end

    # Memoized overridden assignment by user
    def overridden_assignment
      @vdd ||= overridden_assignment_unmemoized
    end

    # Returns the submission date if available; otherwise, nil
    def submitted_at
      @submission && @submission.submitted_at.presence
    end

    def submission_graded?
      @submission && @submission.graded?
    end

    # Returns the most lenient due date if graded; otherwise, nil
    def graded_varied_due_date
      if submission_graded? && !@assignment.submittable_type?
        overridden_assignment.due_at.presence
      end
    end

    # Returns the date the submission was graded if available; otherwise, nil
    def graded_date
      @submission.graded_at if @submission && @submission.grade.present?
    end

  end
end
