module AssignmentSubmissionRoller

  # Generate Rollups since start_at
  #
  # Available options:
  #   - start_at [time]: override default start time
  #   - end_at [time]: override default end time
  #
  #   - verbose [boolean]: print lots of logging info
  def self.rollup_all(opts={})
    # This is intended to run one time to get all back data, then future updates will come as
    # Submissions get created and updated or as due dates change
    start_at = opts[:start_at] || Time.zone.now - 1.years
    end_at = opts[:end_at] || Time.zone.now
    logger.info "Rolling up submissions since #{start_at.inspect} through #{end_at.inspect}" if opts[:verbose]
    submission_scope = Submission.where(:updated_at => start_at..end_at).includes(:assignment)
    update_caches_for_scope(submission_scope)
  end

  def self.update_caches_for_scope(scope)
    columns_needed = 'submissions.id, submissions.user_id, submissions.assignment_id, submissions.submitted_at, submissions.submission_type, submissions.score, submissions.workflow_state'
    scope.select(columns_needed).includes(:student).find_each do |submission|
      Submission.send(:with_exclusive_scope) { update_cache(submission) }
    end
  end

  def self.update_cache(submission, perform_update = true)
    asd = Analytics::AssignmentSubmissionDate.new(submission.assignment.reload, submission.student, submission)
    tardy = Analytics::Tardy.new(asd.due_date, asd.submission_date)
    status = tardy.decision.to_s

    if perform_update
      Submission.where(:id => submission).update_all(:cached_tardy_status => status, :cached_due_date => asd.due_date)
    else
      submission.cached_tardy_status = status
      submission.cached_due_date = asd.due_date
    end
  end
end
