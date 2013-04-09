require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/selenium/common')
require File.expand_path(File.dirname(__FILE__) + '/analytics_common')

describe "analytics course view" do
  it_should_behave_like "analytics tests"

  module StudentBars
    PAGE_VIEWS = '#students .page_views .paper span'
    ASSIGNMENTS = '#students .assignments .paper span'
    PARTICIPATION = '#students .participation .paper span'
  end

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

    context "participation graph" do
      let(:analytics_url) { "/courses/#{@course.id}/analytics" }
      it_should_behave_like "participation graph specs"
    end

    it "should validate finishing assignments graph" do
      finishing_graph_css = '#finishing-assignments-graph'
      setup_variety_assignments
      go_to_analytics("/courses/#{@course.id}/analytics")

      #get assignment bars
      missed_bar = get_bar(finishing_graph_css, @missed_assignment.id)
      late_submission_bar = get_bar(finishing_graph_css, @late_assignment.id)
      on_time_bar = get_bar(finishing_graph_css, @on_time_assignment.id)

      #validate bar colors
      validate_element_fill(missed_bar, GraphColors::SHARP_RED)
      validate_element_fill(late_submission_bar, GraphColors::SHARP_YELLOW)
      validate_element_fill(on_time_bar, GraphColors::SHARP_GREEN)

      #validate first bar tooltip info
      validation_text = [@missed_assignment.title, "Due: " + TextHelper.date_string(@missed_assignment.due_at), "Missing: 100%"]
      validation_text.each { |text| validate_tooltip_text("#{finishing_graph_css} .assignment_#{@missed_assignment.id}.cover", text) }
    end

    it "should validate grades graph" do
      setup_for_grades_graph
      validation_text = ['High: ' + @first_submission_score, @first_assignment.title]
      go_to_analytics("/courses/#{@course.id}/analytics")

      validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{@first_assignment.id}.cover", text) }
    end
  end

  context "students display" do

    def student_bars(info_bar)
      ff(info_bar)
    end

    it "should be absent unless the user has permission to see grades" do
      RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'manage_grades', :override => false)
      RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_all_grades', :override => false)
      go_to_analytics("/courses/#{@course.id}/analytics")
      f('#students').should be_nil
    end

    it "should validate correct number of students are showing up" do
      def student_rows
        ffj('#students div.student') #avoid selenium caching
      end

      go_to_analytics("/courses/#{@course.id}/analytics")
      student_rows.count.should == 1
      student_rows.first.text.should == INITIAL_STUDENT_NAME
      add_students_to_course(2)
      refresh_page #in order to make new students show up
      wait_for_ajaximations # student rows are loaded asynchronously
      student_rows.count.should == 3
    end

    it "should validate current score display for students" do
      randomly_grade_assignments(5)
      go_to_analytics("/courses/#{@course.id}/analytics")
      f('div.current_score').should include_text(current_student_score)
    end

    it "should display student activity for tomorrow" do
      tomorrow = Time.now.utc + 1.day
      page_view(:user => @student, :course => @course, :participated => true, :created_at => tomorrow)

      go_to_analytics("/courses/#{@course.id}/analytics/users/#{@student.id}")
      fj("rect.#{Time.now.utc.strftime("%Y-%m-%d")}").should be_nil
      fj("rect.#{tomorrow.strftime("%Y-%m-%d")}").should be_displayed
    end

    context 'main bars' do

      before (:each) do
        @added_students = add_students_to_course(2)
      end

      it "should validate page views bar for students" do
        page_view_styles = %w(0% 100% 50%)
        2.times { page_view(:user => @student, :course => @course) }
        4.times { page_view(:user => @added_students[0], :course => @course, :participated => true) }
        go_to_analytics("/courses/#{@course.id}/analytics")
        student_bars(StudentBars::PAGE_VIEWS).each_with_index { |page_view_bar, i| page_view_bar.should have_attribute(:style, "right: #{page_view_styles[i]}") }
      end

      it "should validate participation bar for students" do
        page_view_styles = %w(50% 0% 75%)
        page_view(:user => @student, :course => @course, :participated => true)
        2.times { page_view(:user => @added_students[0], :course => @course, :participated => true) }
        4.times { page_view(:user => @added_students[1], :course => @course, :participated => true) }
        go_to_analytics("/courses/#{@course.id}/analytics")
        student_bars(StudentBars::PARTICIPATION).each_with_index { |page_view_bar, i| page_view_bar.should have_attribute(:style, "right: #{page_view_styles[i]}") }
      end
    end

    it "should validate assignments bar for a single student" do
      expected_classes = %w(onTime late missing)
      setup_variety_assignments(false)
      go_to_analytics("/courses/#{@course.id}/analytics")
      assignments_regions = student_bars(StudentBars::ASSIGNMENTS)
      expected_classes.each_with_index { |expected_class, i| assignments_regions[i].should have_class(expected_class) }
    end
  end
end
