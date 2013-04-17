class AssignmentRollupObserver < ActiveRecord::Observer
  observe :submission

  def after_save(submission)
    assignment = submission.assignment
    AssignmentsRoller.send_later_if_production_enqueue_args('rollup_one_assignment', {:singleton => "rollup_one_assignment:#{assignment.global_id}"}, assignment.context, assignment)
  end
end
