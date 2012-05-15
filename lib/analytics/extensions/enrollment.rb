Enrollment.class_eval do
  after_save :recache_course_grade_distribution

  def recache_course_grade_distribution
    # workflow_state_changed? will be true for records that were new, so this
    # will also catch newly created enrollments.
    if student? && !fake_student? && workflow_state_changed?
      # the course may have gained/lost a 'valid' (non-fake active or completed
      # student enrollment), update its cached grade distribution.
      course.recache_grade_distribution
    end
    true
  end
end
