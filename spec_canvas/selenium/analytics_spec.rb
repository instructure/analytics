require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/selenium/common')
require File.expand_path(File.dirname(__FILE__) + '/analytics_common')

describe "analytics" do
  it_should_behave_like "analytics tests"

  ANALYTICS_BUTTON_CSS = '.analytics-grid-button'
  ANALYTICS_BUTTON_TEXT = 'Student Analytics for '

  def student_roster
    ff('.student_roster .user')
  end

  def right_nav_buttons
    ff('#right_nav .button')
  end

  def validate_analytics_button_exists(exists = true)
    student = StudentEnrollment.last.user
    get "/courses/#{@course.id}/users/#{student.id}"
    exists ? right_nav_buttons[0].text.strip!.should == "Student Analytics for #{student.name}" : right_nav_buttons.each { |right_nav_button| right_nav_button.should_not include_text(ANALYTICS_BUTTON_TEXT) }
  end

  def validate_analytics_icons_exist(exist = true)
    get "/courses/#{@course.id}/users"
    if !exist
      ff(ANALYTICS_BUTTON_CSS).should be_empty
    else
      ff(ANALYTICS_BUTTON_CSS).count.should == student_roster.count
    end
  end

  def validate_student_display(student_name)
    f('.student_summary').should include_text(student_name)
  end

  describe "course view" do

    describe "links" do

      before (:each) do
        course_with_teacher_logged_in
        enable_analytics
        add_students_to_course(1)
        @student = StudentEnrollment.last.user
      end

      it "should validate analytics icon link works" do
        get "/courses/#{@course.id}/users"

        expect_new_page_load { student_roster[0].find_element(:css, ANALYTICS_BUTTON_CSS).click }
        validate_student_display(@student.name)
      end

      it "should validate analytics button link works" do
        get "/courses/#{@course.id}/users/#{@student.id}"

        expect_new_page_load { right_nav_buttons[0].click }
        validate_student_display(@student.name)
      end
    end

    context "as an admin" do

      describe "with analytics turned on" do

        before (:each) do
          course_with_admin_logged_in
          enable_analytics
          add_students_to_course(5)
        end

        it "should show analytics icons" do
          validate_analytics_icons_exist
        end

        it "should validate analytics button is showing up on user page" do
          validate_analytics_button_exists
        end
      end

      describe "with analytics turned off" do

        before (:each) do
          course_with_admin_logged_in
          add_students_to_course(5)
        end

        it "should not show analytics icons" do
          validate_analytics_icons_exist(false)
        end

        it "should validate analytics button is not showing up on user page" do
          validate_analytics_button_exists(false)
        end
      end
    end

    context "as a teacher" do

      describe "with analytics permissions on" do

        before (:each) do
          enable_analytics
          course_with_teacher_logged_in
          add_students_to_course(5)
        end

        it "should validate analytics icons are showing up on users page" do
          validate_analytics_icons_exist
        end

        it "should validate analytics button is showing up on user page" do
          validate_analytics_button_exists
        end
      end

      describe "with analytics permissions off" do

        before (:each) do
          enable_analytics
          disable_teacher_permissions
          course_with_teacher_logged_in
          add_students_to_course(5)
        end

        it "should not show analytics icons on users page if analytics is not enabled" do
          validate_analytics_icons_exist(false)
        end

        it "should not show analytics button on user page if analytics is not enabled" do
          validate_analytics_button_exists(false)
        end
      end
    end
  end

  describe "analytics view" do

    before (:each) do
      enable_analytics
      @teacher = course_with_teacher_logged_in.user
      @course.update_attributes(:start_at => 15.days.ago, :conclude_at => 2.days.from_now)
      @course.save!
      add_students_to_course(1)
      @student = StudentEnrollment.last.user
    end

    it "should validate correct user is showing up on analytics page" do
      go_to_analytics

      validate_student_display(@student.name)
    end

    it "should validate current total display" do
      randomly_grade_assignments(5)
      go_to_analytics

      f('.student_summary').should include_text(current_student_score)
    end

    context 'participation view' do
      let(:go_to_course_view) { false }
      it_should_behave_like "participation graph specs"
    end

    it "should validate responsiveness graph" do
      single_message = '1 message'
      multiple_message = '3 messages'
      users_css = ["#responsiveness-graph .student", "#responsiveness-graph .instructor"]

      def add_message(conversation, number_to_add)
        number_to_add.times { conversation.add_message("message") }
      end

      @students_id = [@student.id]
      @teachers_id = [@teacher.id]

      [@teacher, @student].each do |user|
        channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
        channel.confirm
      end

      @teacher_conversation = @teacher.initiate_conversation(@students_id)
      @student_conversation = @student.initiate_conversation(@teachers_id)
      add_message(@teacher_conversation, 1)
      add_message(@student_conversation, 1)
      go_to_analytics

      users_css.each { |user_css| validate_tooltip_text(user_css, single_message) }

      # add more messages
      add_message(@teacher_conversation, 2)
      add_message(@student_conversation, 2)
      refresh_page # have to refresh to get new message count
      wait_for_ajaximations
      users_css.each { |user_css| validate_tooltip_text(user_css, multiple_message) }
    end

    it "should validate finishing assignments graph" do
      # setting up assignments
      setup_variety_assignments
      go_to_analytics

      missed_diamond = get_diamond(@missed_assignment.id)
      no_due_date_diamond = get_diamond(@no_due_date_assignment.id)
      late_submission_diamond = get_diamond(@late_assignment.id)
      on_time_diamond = get_diamond(@on_time_assignment.id)

      validate_element_fill(missed_diamond, GraphColors::DARK_RED)
      validate_element_fill(late_submission_diamond, GraphColors::DARK_YELLOW)
      validate_element_fill(on_time_diamond, GraphColors::DARK_GREEN)
      validate_element_fill(no_due_date_diamond, 'none')
      validate_element_stroke(no_due_date_diamond, GraphColors::FRAME)
    end

    it "should validate grades graph" do
      randomly_grade_assignments(10)
      first_assignment = @course.active_assignments.first
      first_submission_score = first_assignment.submissions.first.score.to_s
      validation_text = ['Score: ' + first_submission_score + ' / 100', first_assignment.title]
      setup_for_grades_graph
      go_to_analytics
      validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{first_assignment.id}.cover", text) }
    end

    it "should validate a non-graded assignment on graph" do
      @course.assignments.create!(:title => 'new assignment', :points_possible => 10)
      first_assignment = @course.active_assignments.first
      go_to_analytics

      driver.execute_script("$('#grades-graph .assignment_#{first_assignment.id}.cover').mouseover()")
      tooltip = f(".analytics-tooltip")
      tooltip.text.should == first_assignment.title
    end

    describe "student combo box" do

      def validate_combobox_presence(is_present = true)
        if is_present
          f('.ui-combobox').should be_displayed
        else
          f('.ui-combobox').should be_nil
        end
      end

      it "should validate student combo box shows up when >= 2 students are in the course" do
        add_students_to_course(1)
        go_to_analytics
        validate_combobox_presence
      end

      it "should not show the combo box when course student count = 1" do
        go_to_analytics
        validate_combobox_presence(false)
      end

      it "should display the correct student info when selected in the combo box" do
        def select_next_student(nav_button, expected_student)
          nav_button.click
          wait_for_ajaximations
          driver.current_url.should include(expected_student.id.to_s)
        end

        def validate_combobox_name(student_name)
          f('.ui-selectmenu-status').should include_text(student_name)
        end

        def validate_first_students_grade_graph
          first_assignment = @course.active_assignments.first
          first_submission_score = first_assignment.submissions.first.score.to_s
          validation_text = ['Score: ' + first_submission_score + ' / 100', first_assignment.title]
          validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{first_assignment.id}.cover", text) }
        end

        added_students = add_students_to_course(1)
        graded_assignments = randomly_grade_assignments(5)
        go_to_analytics
        next_button = f('.ui-combobox-next')
        prev_button = f('.ui-combobox-prev')

        #check that first student in course is selected
        driver.current_url.should include(@student.id.to_s)
        validate_combobox_name(@student.name)

        #validate grades graph for first graded student
        validate_first_students_grade_graph

        #change to the next student
        select_next_student(next_button, added_students[0])
        validate_combobox_name(added_students[0].name)
        assignment_diamond = get_diamond(graded_assignments[0].id)
        validate_element_fill(assignment_diamond, GraphColors::DARK_RED)

        #change back to the first student
        select_next_student(prev_button, @student)
        validate_combobox_name(@student.name)
        validate_first_students_grade_graph
      end
    end
  end
end
