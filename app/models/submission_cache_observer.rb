class SubmissionCacheObserver < ActiveRecord::Observer
  observe :assignment_override, :assignment, :enrollment, :group_membership, :submission

  def after_create(record)
    unless record.is_a? Submission
      class_name = record.class.to_s.underscore
      class_name = 'enrollment' if class_name =~ /enrollment/
      send("cache_for_#{class_name}".to_sym, record)
    end
  end

  def after_update(record)
    unless record.is_a? Submission
      class_name = record.class.to_s.underscore

      if class_name == 'assignment_override'
        cache_for_assignment_override(record)
      elsif class_name == 'assignment' and record.due_at_changed?
        cache_for_assignment(record)
      elsif class_name =~ /enrollment/ and record.course_section_id_changed?
        cache_for_enrollment(record)
      elsif class_name == 'group_membership' and record.group_id_changed?
        cache_for_group_membership(record)
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
  handle_asynchronously_if_production :cache_for_assignment_override,
        :singleton => proc { |observer,override| "assignment_rollup_for_assignment_override:#{override.global_id}" }

  def cache_for_assignment(assignment)
    AssignmentSubmissionRoller.update_caches_for_scope(assignment.submissions)
  end
  handle_asynchronously_if_production :cache_for_assignment,
        :singleton => proc { |observer,assignment| "assignment_rollup_for_assignment:#{assignment.global_id}" }

  def cache_for_enrollment(enrollment)
    AssignmentSubmissionRoller.update_caches_for_scope(enrollment.user.submissions)
  end
  handle_asynchronously_if_production :cache_for_enrollment,
        :singleton => proc { |observer,enrollment| "assignment_rollup_for_enrollment:#{enrollment.global_id}" }

  def cache_for_group_membership(membership)
    AssignmentSubmissionRoller.update_caches_for_scope(membership.user.submissions)
  end
  handle_asynchronously_if_production :cache_for_group_membership,
        :singleton => proc { |observer,membership| "assignment_rollup_for_membership:#{membership.global_id}" }

end
