require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/selenium/common')
require File.expand_path(File.dirname(__FILE__) + '/analytics_common')

describe "analytics course view" do
  it_should_behave_like "analytics tests"

  INITIAL_STUDENT_NAME = 'initial test student'

  def get_bar(graph_selector, assignment_id)
    driver.execute_script("return $('#{graph_selector} .assignment_#{assignment_id}').prev()[0]")
  end

  before (:each) do
    enable_analytics
    enable_teacher_permissions
    course_with_teacher_logged_in.user
    @course.update_attributes(:start_at => 15.days.ago, :conclude_at => 2.days.from_now)
    @course.save!
    @student = User.create!(:name => INITIAL_STUDENT_NAME)
    @course.enroll_student(@student).accept!
  end

  context "course graphs" do

    #TODO: figure out how to seed page views
    it "should validate participation graph"

    it "should validate finishing assignments graph" do
      finishing_graph_css = '#finishing-assignments-graph'
      setup_variety_assignments
      go_to_analytics(true)

      #get assignment bars
      missed_bar = get_bar(finishing_graph_css, @missed_assignment.id)
      late_submission_bar = get_bar(finishing_graph_css, @late_assignment.id)
      on_time_bar = get_bar(finishing_graph_css, @on_time_assignment.id)

      #validate bar colors
      validate_element_fill(missed_bar, GraphColors::SHARP_RED)
      validate_element_fill(late_submission_bar, GraphColors::SHARP_YELLOW)
      validate_element_fill(on_time_bar, GraphColors::SHARP_GREEN)

      #validate first bar tooltip info
      validation_text = [@missed_assignment.title, "Due: " + @missed_assignment.due_at.strftime("%a %b %d %Y"), "Missing: 100%"]
      validation_text.each { |text| validate_tooltip_text("#{finishing_graph_css} .assignment_#{@missed_assignment.id}.cover", text) }
    end

    it "should validate grades graph" do
      setup_for_grades_graph
      validation_text = ['High: ' + @first_submission_score, @first_assignment.title]
      go_to_analytics(true)

      validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{@first_assignment.id}.cover", text) }
    end
  end

  context "students display" do

    it "should validate correct number of students are showing up" do
      def student_rows
        ff('#students div.student')
      end

      go_to_analytics(true)

      student_rows.count.should == 1
      student_rows.first.text.should == INITIAL_STUDENT_NAME
      add_students_to_course(2)
      refresh_page #in order to make new students show up
      student_rows.count.should == 3
    end

    #TODO: figure out how to seed page views
    it "should validate page views bar for students"

    it "should validate participations bar for students"

    it "should validate assignments bar for students"

    it "should validate current score display for students" do
      randomly_grade_assignments(5)
      go_to_analytics(true)
      f('div.current_score').should include_text(current_student_score)
    end
  end
end
