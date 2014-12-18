#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

shared_examples_for "analytics tests" do
  include_examples "in-process server selenium tests"

  module GraphColors
    FRAME = "#959595"
    GRID = "#cccccc"
    BLUE = "#33acdf"
    ORANGE = "#f59331"
    LIGHT_BLUE = "#c1e6f5"
    LIGHT_GREEN = "#95ee86"
    DARK_GREEN = "#2fa23e"
    SHARP_GREEN = "#8cd20d"
    LIGHT_YELLOW = "#efe33e"
    DARK_YELLOW = "#b3a700"
    SHARP_YELLOW = "#f6bd00"
    LIGHT_RED = "#dea8a9"
    DARK_RED = "#da181d"
    SHARP_RED = "#d21d1a"
    NONE = "#cccccc"
  end

  def enable_analytics
    @account = Account.default
    @account.enable_service(:analytics)
    @account.save!
    @account
  end

  def disable_analytics
    @account = Account.default
    @account.disable_service(:analytics)
    @account.save!
    @account
  end

  def page_view(opts={})
    Setting.set('enable_page_views', 'db')
    course = opts[:course] || @course
    user = opts[:user] || @student
    controller = opts[:controller] || 'assignments'
    summarized = opts[:summarized] || nil

    page_view = PageView.new(
        :context => course,
        :user => user,
        :controller => controller)

    page_view.summarized = summarized
    page_view.request_id = SecureRandom.hex(10)
    page_view.created_at = opts[:created_at] || Time.now

    if opts[:participated]
      page_view.participated = true
      access = page_view.build_asset_user_access
      access.display_name = 'Some Asset'
    end

    page_view.store
    page_view
  end

  def enable_teacher_permissions
    RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => true)
    Rails.cache.delete(['context_permissions', @course, @teacher].cache_key)
  end

  def disable_teacher_permissions
    RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_analytics', :override => false)
    Rails.cache.delete(['context_permissions', @course, @teacher].cache_key)
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

  def go_to_analytics(analytics_url)
    get analytics_url
    wait_for_ajaximations
  end

  def randomly_grade_assignments(number_of_assignments, student = @student)
    graded_assignments = []
    number_of_assignments.times do |i|
      assignment = @course.active_assignments.create!(:title => "new assignment #{i}", :points_possible => 100, :due_at => Time.now.utc, :submission_types => "online")
      assignment.submit_homework(student)
      assignment.grade_student(student, :grade => rand(100) + 1)
      graded_assignments.push(assignment)
    end
    graded_assignments
  end

  def validate_tooltip_text(css_selector, text)
    driver.execute_script("$('#{css_selector}').mouseover()")
    tooltip = f('.analytics-tooltip')
    expect(tooltip).to include_text(text)
    tooltip
  end

  def setup_variety_assignments(add_no_due_date = true)
    @missed_assignment = @course.assignments.create!(:title => "missed assignment", :due_at => 5.days.ago, :points_possible => 10, :submission_types => 'online_url')
    @no_due_date_assignment = @course.assignments.create!(:title => 'no due date assignment', :due_at => nil, :points_possible => 20, :submission_types => 'online_url') if add_no_due_date
    @late_assignment = @course.assignments.create!(:title => 'late assignment', :due_at => 1.day.ago, :points_possible => 20, :submission_types => 'online_url')
    @late_assignment.submit_homework(@student, :submission_type => 'online_url')
    @on_time_assignment = @course.assignments.create!(:title => 'on time submission', :due_at => 2.days.from_now, :points_possible => 10, :submission_types => 'online_url')
    @on_time_assignment.submit_homework(@student, :submission_type => 'online_url')
  end

  def current_student_score
    StudentEnrollment.last.computed_current_score.to_s
  end

  def setup_for_grades_graph
    @first_assignment = randomly_grade_assignments(10).first
    @first_submission_score = @first_assignment.submissions.first.score.to_s
  end

  def validate_element_fill(element, fill_hex_color)
    expect(element.attribute('fill')).to eq "#{fill_hex_color}"
  end

  def validate_element_stroke(element, stroke_hex_color)
    expect(element.attribute('stroke')).to eq "#{stroke_hex_color}"
  end

  def format_date(date)
    date.strftime("%Y-%m-%d")
  end

  def date_selector(date, graph_selector = '#participating-graph')
    "#{graph_selector} .#{format_date(date)}"
  end

  def get_rectangle(date, graph_selector = '#participating-graph')
    driver.execute_script("return $('#{date_selector(date, graph_selector)}').prev()[0]")
  end

  def get_diamond(assignment_id)
    driver.execute_script("return $('#assignment-finishing-graph .assignment_#{assignment_id}').prev()[0]")
  end

  def student_roster
    ff('.student_roster .user')
  end

  def right_nav_buttons
    ff('#right_nav a')
  end

  def validate_analytics_button_exists(exists = true)
    student = StudentEnrollment.last.user
    get "/courses/#{@course.id}/users/#{student.id}"
    exists ? (expect(right_nav_buttons[0].text.strip).to eq "Analytics") : right_nav_buttons.each { |right_nav_button| expect(right_nav_button).not_to include_text(ANALYTICS_BUTTON_TEXT) }
  end

  def validate_analytics_icons_exist(exist = true)
    get "/courses/#{@course.id}/users"
    wait_for_ajaximations
    if !exist
      expect(ff(ANALYTICS_BUTTON_CSS)).to be_empty
    else
      expect(ff(ANALYTICS_BUTTON_CSS).count).to eq student_roster.count
    end
  end

  def validate_student_display(student_name)
    expect(f('.student_summary')).to include_text(student_name)
  end

  shared_examples_for "analytics permissions specs" do
    it "should validate analytics icons display" do
      validate_analytics_icons_exist(validate)
    end

    it "should validate analytics button display" do
      validate_analytics_button_exists(validate)
    end
  end

  shared_examples_for "participation graph specs" do
    it "should validate participating graph with a single page view" do
      page_view(:user => @student, :course => @course)
      go_to_analytics(analytics_url)
      validate_tooltip_text(date_selector(Time.now), '1 page view')
    end

    it "should validate participating graph with multiple page views" do
      page_view_count = 10
      page_view_count.times { page_view(:user => @student, :course => @course) }
      go_to_analytics(analytics_url)
      validate_tooltip_text(date_selector(Time.now), page_view_count.to_s + ' page views')
    end

    it "should validate participating graph with multiple page views on multiple days" do
      old_page_views_date = Time.now - 2.days
      dates = [old_page_views_date, Time.now]
      number_of_page_views = 5
      number_of_page_views.times { page_view(:user => @student, :course => @course) }
      number_of_page_views.times { page_view(:user => @student, :course => @course, :created_at => old_page_views_date) }
      go_to_analytics(analytics_url)
      dates.each { |date| validate_tooltip_text(date_selector(date), number_of_page_views.to_s + ' page views') }
    end

    it "should validate the graph color when a student took action on that day" do
      page_view(:user => @student, :course => @course, :participated => true)
      go_to_analytics(analytics_url)
      validate_element_fill(get_rectangle(Time.now), GraphColors::ORANGE)
      validate_tooltip_text(date_selector(Time.now), '1 participation')
    end

    it "should validate the participation and non participation display" do
      old_page_view_date = Time.now - 3.days
      rectangles = []
      dates = [old_page_view_date, Time.now]
      page_view(:user => @student, :course => @course)
      page_view(:user => @student, :course => @course, :participated => true, :created_at => old_page_view_date)
      go_to_analytics(analytics_url)
      dates.each do |date|
        rect = get_rectangle(date)
        rectangles.push(rect)
      end
      validate_element_fill(rectangles[0], GraphColors::ORANGE)
      validate_element_fill(rectangles[1], GraphColors::BLUE)
    end
  end
end
