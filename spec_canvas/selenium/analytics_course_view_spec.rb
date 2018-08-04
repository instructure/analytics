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

require_relative '../../../../../spec/selenium/common'
require_relative 'analytics_common'

describe "analytics course view" do
  include_examples "analytics tests"

  module StudentBars
    PAGE_VIEWS = '#students .page_views .paper span'
    SUBMISSIONS = '#students .submissions .paper span'
    PARTICIPATION = '#students .participation .paper span'
  end

  INITIAL_STUDENT_NAME = 'initial test student'

  def get_bar(graph_selector, assignment_id)
    driver.execute_script("return $('#{graph_selector} .assignment_#{assignment_id}').prev()[0]")
  end

  before(:once) do
    enable_analytics
    enable_teacher_permissions
    course_with_teacher(active_all: true)
    @course.update_attributes(:start_at => 15.days.ago, :conclude_at => 2.days.from_now)
    @course.save!
    student_in_course(name: INITIAL_STUDENT_NAME, active_all: true)
  end

  before(:each) { user_session(@teacher) }

  context "course home page" do

    it 'should show the analytics button on the course home page' do
      get "/courses/#{@course.id}"
      wait_for_ajaximations
      expect(find('div.course-options').text).to include("Analytics")
    end
  end

  context "course graphs" do

    context "participation graph" do
      let(:analytics_url) { "/courses/#{@course.id}/analytics" }
      include_examples "participation graph specs"
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
      validation_text = ['High: ' + @first_submission_score.to_i.to_s, @first_assignment.title]
      go_to_analytics("/courses/#{@course.id}/analytics")

      validation_text.each { |text| validate_tooltip_text("#grades-graph .assignment_#{@first_assignment.id}.cover", text) }
    end

    describe "graph toggle switch" do
      it "should hide the graphs and show table when selected" do
        go_to_analytics("/courses/#{@course.id}/analytics")
        expect(f('#activities-table')).not_to be_displayed
        expect(f('.graph')).to be_displayed
        move_to_click('.AnalyticsToggle label.ic-Super-toggle--ui-switch')
        expect(f('#activities-table')).to be_displayed
        expect(f('.graph')).not_to be_displayed
      end
    end
  end

  context "students display" do

    it "should be absent unless the user has permission to see grades" do
      RoleOverride.manage_role_override(@account, teacher_role, 'manage_grades', :override => false)
      RoleOverride.manage_role_override(@account, teacher_role, 'view_all_grades', :override => false)
      go_to_analytics("/courses/#{@course.id}/analytics")
      expect(f('#content')).not_to contain_css('#students')
    end

    it "should validate correct number of students are showing up" do
      def student_rows
        ffj('#students div.student') #avoid selenium caching
      end

      go_to_analytics("/courses/#{@course.id}/analytics")
      expect(student_rows.count).to eq 1
      expect(student_rows.first.text).to eq INITIAL_STUDENT_NAME
      add_students_to_course(2)
      refresh_page #in order to make new students show up
      wait_for_ajaximations # student rows are loaded asynchronously
      expect(student_rows.count).to eq 3
    end

    it "should validate current score display for students" do
      randomly_grade_assignments(5)
      go_to_analytics("/courses/#{@course.id}/analytics")
      expect(find("#student_#{@student.id} .current_score")).to include_text(current_student_score)
    end

    it "should display student activity for tomorrow" do
      tomorrow = Time.now.utc + 1.day
      page_view(:user => @student, :course => @course, :participated => true, :created_at => tomorrow)

      go_to_analytics("/courses/#{@course.id}/analytics/users/#{@student.id}")
      expect(fj("rect.#{tomorrow.strftime("%Y-%m-%d")}")).to be_displayed
    end

    it "should count pageviews" do
      3.times { page_view(:user => @student, :course => @course) }
      go_to_analytics("/courses/#{@course.id}/analytics")
      expect(find("#student_#{@student.id} .page_views")).to include_text('3')
    end

    it "should count submissions" do
      setup_variety_assignments(false)
      go_to_analytics("/courses/#{@course.id}/analytics")
      # Only 2 submissions are real now
      expect(find("#student_#{@student.id} .submissions")).to include_text('2')
      expect(find("#student_#{@student.id} .on_time")).to include_text('1')
      expect(find("#student_#{@student.id} .late")).to include_text('1')
      expect(find("#student_#{@student.id} .missing")).to include_text('1')
    end
  end

  context "student tray" do

    before(:once) do
      @student1 = @student
      @enrollment = student_in_course(course: @course, name: 'initial test student2', active_all: true)
      @enrollment.update_attribute(:last_activity_at, Time.zone.now)
      @student2 = @student
      @account.enable_feature!(:student_context_cards)
      Timecop.freeze(1.day.ago) do
        3.times { page_view(:user => @student1, :course => @course, :participated => true) }
        3.times { page_view(:user => @student2, :course => @course, :participated => true) }
      end
      randomly_grade_assignments(8)
      create_past_due(3, 2)
    end

    before { preload_graphql_schema }

    it "should display context card content", priority: "1", test_id: 3109484 do
      get("/courses/#{@course.id}/gradebook")
      f("a[data-student_id='#{@student2.id}']").click
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("initial test student")
      expect(f(".StudentContextTray-Header__CourseName")).to include_text("Unnamed Course")
      expect(f("body")).to contain_jqcss(".StudentContextTray-Header__Content:contains(Section: Unnamed Course)")
      expect(f(".StudentContextTray-Header__Actions")).to contain_css(".icon-email")
      expect(f("body")).to contain_jqcss(".StudentContextTray-QuickLinks__Link:contains(Grades)")
      expect(f("body")).to contain_jqcss(".StudentContextTray-QuickLinks__Link:contains(Analytics)")
      expect(ff(".StudentContextTray-Progress__Bar").length).to eq 10
      expect(f(".StudentContextTray-Header__Name h2 a")).
        to have_attribute("href", "/courses/#{@course.id}/users/#{@student2.id}")
      expect(fj(".StudentContextTray-QuickLinks__Link:first a")).
        to have_attribute("href", "/courses/#{@course.id}/grades/#{@student2.id}")
      expect(fj(".StudentContextTray-QuickLinks__Link:eq(1) a")).
        to have_attribute("href", "/courses/#{@course.id}/analytics/users/#{@student2.id}")
      expect(f("body")).to contain_jqcss(".StudentContextTray-Header__Content:contains(Last login)")
    end

    it "should switch student displayed in tray", priority: "1", test_id: 3022079 do
      enable_cache do
        get("/courses/#{@course.id}/gradebook")
        f("a[data-student_id='#{@student1.id}']").click
        expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("initial test student")
        f("a[data-student_id='#{@student2.id}']").click
        f("a[data-student_id='#{@student2.id}']").click # first click closes the tray, second re-opens it
        expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("initial test student2")
      end
    end
  end
end
