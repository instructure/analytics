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
      varied_due_date.due_at
    end

  protected

    # Make it easy to stub VariedDueDate out for tests
    def varied_due_date_unmemoized
      VariedDueDate.new(@assignment, @user)
    end

    # Memoized varied due date by user
    def varied_due_date
      @vdd ||= varied_due_date_unmemoized
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
        varied_due_date.due_at.presence
      end
    end

    # Returns the date the submission was graded if available; otherwise, nil
    def graded_date
      @submission && @submission.graded_at.presence
    end

  end
end
