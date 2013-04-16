class SubmissionCacheObserver < ActiveRecord::Observer
  observe :assignment_override, :assignment, :enrollment, :group_membership, :submission

  def after_create(record)
    unless record.is_a? Submission
      class_name = record.class.to_s.underscore
      class_name = 'enrollment' if class_name =~ /enrollment/
      send_later_if_production_enqueue_args("cache_for_#{class_name}", {:singleton => "assignment_rollup_for_#{class_name}:#{record.global_id}"}, record)
    end
  end

  def after_update(record)
    unless record.is_a? Submission
      class_name = record.class.to_s.underscore

      if class_name == 'assignment_override'
        send_later_if_production_enqueue_args('cache_for_assignment_override', {:singleton => "assignment_rollup_for_assignment_override:#{record.global_id}" }, record)
      elsif class_name == 'assignment' and record.due_at_changed?
        send_later_if_production_enqueue_args('cache_for_assignment', {:singleton => "assignment_rollup_for_assignment:#{record.global_id}"}, record)
      elsif class_name =~ /enrollment/ and record.course_section_id_changed?
        send_later_if_production_enqueue_args('cache_for_enrollment', {:singleton => "assignment_rollup_for_enrollment:#{record.global_id}"}, record)
      elsif class_name == 'group_membership' and record.group_id_changed?
        send_later_if_production_enqueue_args('cache_for_group_membership', {:singleton => "assignment_rollup_for_group_membership:#{record.global_id}"}, record)
      end

    end
  end

  def before_save(record)
    if record.is_a?(Submission) && (record.new_record? || record.submitted_at_changed?)
      AssignmentSubmissionRoller.update_cache(record, false)
    end
  end

  def cache_for_assignment_override(override)
    if override.assignment
      students = override.applies_to_students
      students_scope = override.assignment.submissions.where(:user_id => students)
      AssignmentSubmissionRoller.update_caches_for_scope(students_scope)
    end
  end

  def cache_for_assignment(assignment)
    AssignmentSubmissionRoller.update_caches_for_scope(assignment.submissions)
  end

  def cache_for_enrollment(enrollment)
    AssignmentSubmissionRoller.update_caches_for_scope(enrollment.user.submissions)
  end

  def cache_for_group_membership(membership)
    AssignmentSubmissionRoller.update_caches_for_scope(membership.user.submissions)
  end

end
