module AssignmentsRoller

  def self.rollup_all(options={})
    logger.info "Rolling up all assignments"

    Course.active.useful_find_each do |course|
      assignments = ::Analytics::Assignments.assignment_scope_for(course)
      logger.info "Rolling up #{assignments.count} Assignments for course #{course.id}" if options[:verbose]
      assignments.each do |assignment|
        rollup_one_assignment_immediately(course, assignment, options)
      end
    end
  end

  def self.rollup_one_assignment(course, assignment, options = {})
    rollup_one_assignment_immediately(course, assignment, options)
  end
  singleton_class.handle_asynchronously_if_production :rollup_one_assignment,
        :singleton => proc { |roller,course,assignment| "rollup_one_assignment:#{assignment.global_id}" }

  def self.rollup_one_assignment_immediately(course, assignment, options = {})
    rollup_one(course, assignment, nil, options)
    course.active_course_sections.each do |section|
      rollup_one(course, assignment, section, options)
      logger.info "Finished rolling up Assignments for course #{course.id} section #{section.id}" if options[:verbose]
    end
  end

  def self.rollup_one(course, assignment, section, options={})
    course.shard.activate do
      submissions_scope = ::Analytics::Course.submission_scope_for(assignment)
      #these scopes are based on what I found in lib/analytics/course.rb
      enrollments_scope = if section.present?
        section.all_enrollments
      else
        course.all_student_enrollments
      end
      enrollments_scope = enrollments_scope.where(:workflow_state => ['active', 'completed'])
      student_count = enrollments_scope.count(:user_id, :distinct => true)
      AssignmentRollup.init(assignment, section, submissions_scope, student_count)
      logger.info "Rolled up assignment #{assignment.id} for course #{course.id}, section #{section.nil? ? 'none' : section.id}." if options[:verbose]
    end
  end


  def self.logger
    ActiveRecord::Base.logger
  end

  def self.slaved
    ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) { yield }
  end
end
