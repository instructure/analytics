class AssignmentRollupObserver < ActiveRecord::Observer
  observe :submission

  def after_save(submission)
    AssignmentsRoller.rollup_one_assignment(submission.assignment.context, submission.assignment)
  end
end
