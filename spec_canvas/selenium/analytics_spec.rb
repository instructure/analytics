require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/selenium/common')

describe "analytics" do
  it_should_behave_like "in-process server selenium tests"

  ANALYTICS_BUTTON_CSS = '.analytics-grid-button'
  ANALYTICS_BUTTON_TEXT = 'Student Analytics for '

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
    number_to_add.times do |i|
      student = User.create!(:name => "analytics_student_#{i}")
      @course.enroll_student(student).accept!
    end
  end

  def student_roster
    ff('.student_roster .user')
  end

  def right_nav_buttons
    ff('#right_nav .button')
  end

  def validate_analytics_button_exists(exists = true)
    student = StudentEnrollment.last.user
    get "/courses/#{@course.id}/users/#{student.id}"
    if !exists
      right_nav_buttons.each { |right_nav_button| right_nav_button.should_not include_text(ANALYTICS_BUTTON_TEXT) }
    else
      right_nav_buttons[0].text.strip!.should == "Student Analytics for #{student.name}"
    end
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
        enable_teacher_permissions
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
          enable_teacher_permissions
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

    def go_to_analytics
      get "/analytics/courses/#{@course.id}/users/#{@student.id}"
      wait_for_ajaximations
    end

    def randomly_grade_assignments(number_of_assignments)
      number_of_assignments.times do |i|
        assignment = @course.active_assignments.create!(:title => "new assignment #{i}", :points_possible => 100, :due_at => Time.now.utc)
        assignment.submit_homework(@student)
        assignment.grade_student(@student, :grade => rand(100) + 1)
      end
    end

    def validate_tooltip_text(css_selector, text)
      driver.execute_script("$('#{css_selector}').mouseover()")
      tooltip = f('.analytics-tooltip')
      tooltip.should include_text(text)
      tooltip
    end

    before (:each) do
      enable_analytics
      enable_teacher_permissions
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

      computed_student_score = StudentEnrollment.last.computed_current_score.to_s
      f('.student_summary').should include_text(computed_student_score)
    end

    it "should validate participating graph" do
      pending("need to figure out how to seed page views")
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
      def get_diamond(assignment_id)
        driver.execute_script("return $('#assignment-finishing-graph .assignment_#{assignment_id}').prev()[0]")
      end

      # setting up assignments
      missed_assignment = @course.assignments.create!(:title => "missed assignment", :due_at => 5.days.ago, :points_possible => 10)
      no_due_date_assignment = @course.assignments.create!(:title => 'no due date assignment', :due_at => nil, :points_possible => 20)
      late_assignment = @course.assignments.create!(:title => 'late assignment', :due_at => 1.day.ago, :points_possible => 20, :submission_types => 'online_url')
      late_assignment.submit_homework(@student, :submission_type => 'online_url')
      on_time_assignment = @course.assignments.create!(:title => 'on time submission', :due_at => 2.days.from_now, :points_possible => 10, :submission_types => 'online_url')
      on_time_assignment.submit_homework(@student, :submission_type => 'online_url')
      go_to_analytics

      missed_diamond = get_diamond(missed_assignment.id)
      no_due_date_diamond = get_diamond(no_due_date_assignment.id)
      late_submission_diamond = get_diamond(late_assignment.id)
      on_time_diamond = get_diamond(on_time_assignment.id)

      missed_diamond.attribute('fill').should == "#da181d"
      late_submission_diamond.attribute('fill').should == '#b3a700'
      on_time_diamond.attribute('fill').should == '#2fa23e'
      no_due_date_diamond.attribute('fill').should == "none"
      no_due_date_diamond.attribute('stroke').should == "#a1a1a1"
    end

    it "should validate grades graph" do
      randomly_grade_assignments(10)
      first_assignment = Assignment.first
      first_submission_score = Submission.first.score.to_s
      validation_text = ['Score: ' + first_submission_score + ' / 100', first_assignment.title]
      go_to_analytics
      validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{first_assignment.id}.cover", text) }
    end

    it "should validate a non-graded assignment on graph" do
      @course.assignments.create!(:title => 'new assignment', :points_possible => 10)
      first_assignment = Assignment.first
      go_to_analytics

      driver.execute_script("$('#grades-graph .assignment_#{first_assignment.id}.cover').mouseover()")
      tooltip = f(".analytics-tooltip")
      tooltip.text.should == first_assignment.title
    end
  end
end
