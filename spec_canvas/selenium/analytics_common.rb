shared_examples_for "analytics tests" do
  it_should_behave_like "in-process server selenium tests"

  module GraphColors
    BLUE = "#29abe1"
    DARK_GRAY = "#898989"
    GRAY = "#a1a1a1"
    LIGHT_GRAY = "#cccccc"
    LIGHT_GREEN = "#95ee86"
    DARK_GREEN = "#2fa23e"
    SHARP_GREEN = "#8cd20d"
    LIGHT_YELLOW = "#efe33e"
    DARK_YELLOW = "#b3a700"
    SHARP_YELLOW = "#f6bd00"
    LIGHT_RED = "#dea8a9"
    DARK_RED = "#da181d"
    SHARP_RED = "#d21d1a"
  end

  def enable_analytics
    @account = Account.last
    if @account.allowed_services.nil?;
      @account.allowed_services = '+analytics'
    else
      @account.allowed_services += ',+analytics'
    end
    @account.save!
    @account
  end

  def enable_teacher_permissions
    RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => true)
  end

  def add_students_to_course(number_to_add)
    added_students = []
    number_to_add.times do |i|
      student = User.create!(:name => "analytics_student_#{i}")
      @course.enroll_student(student).accept!
      added_students.push(student)
    end
    added_students
  end

  def go_to_analytics(course_view = false)
    url = course_view ? "/analytics/courses/#{@course.id}" : "/analytics/courses/#{@course.id}/users/#{@student.id}"
    get url
    wait_for_ajaximations
  end

  def randomly_grade_assignments(number_of_assignments)
    graded_assignments = []
    number_of_assignments.times do |i|
      assignment = @course.active_assignments.create!(:title => "new assignment #{i}", :points_possible => 100, :due_at => Time.now.utc)
      assignment.submit_homework(@student)
      assignment.grade_student(@student, :grade => rand(100) + 1)
      graded_assignments.push(assignment)
    end
    graded_assignments
  end

  def validate_tooltip_text(css_selector, text)
    driver.execute_script("$('#{css_selector}').mouseover()")
    tooltip = f('.analytics-tooltip')
    tooltip.should include_text(text)
    tooltip
  end

  def setup_variety_assignments
    @missed_assignment = @course.assignments.create!(:title => "missed assignment", :due_at => 5.days.ago, :points_possible => 10)
    @no_due_date_assignment = @course.assignments.create!(:title => 'no due date assignment', :due_at => nil, :points_possible => 20)
    @late_assignment = @course.assignments.create!(:title => 'late assignment', :due_at => 1.day.ago, :points_possible => 20, :submission_types => 'online_url')
    @late_assignment.submit_homework(@student, :submission_type => 'online_url')
    @on_time_assignment = @course.assignments.create!(:title => 'on time submission', :due_at => 2.days.from_now, :points_possible => 10, :submission_types => 'online_url')
    @on_time_assignment.submit_homework(@student, :submission_type => 'online_url')
  end

  def current_student_score
    StudentEnrollment.last.computed_current_score.to_s
  end

  def setup_for_grades_graph
    randomly_grade_assignments(10)
    @first_assignment = Assignment.first
    @first_submission_score = Submission.first.score.to_s
  end

  def validate_element_fill(element, fill_hex_color)
    element.attribute('fill').should == "#{fill_hex_color}"
  end

  def validate_element_stroke(element, stroke_hex_color)
    element.attribute('stroke').should == "#{stroke_hex_color}"
  end
end