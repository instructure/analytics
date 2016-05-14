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

  before (:each) do
    enable_analytics
    enable_teacher_permissions
    course_with_teacher_logged_in.user
    @course.update_attributes(:start_at => 15.days.ago, :conclude_at => 2.days.from_now)
    @course.save!
    @student = User.create!(:name => INITIAL_STUDENT_NAME)
    @course.enroll_student(@student).accept!
  end

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
        move_to_click('label[for=graph_table_toggle]')
        expect(f('#activities-table')).to be_displayed
        expect(f('.graph')).not_to be_displayed
      end
    end
  end

  context "students display" do

    it "should be absent unless the user has permission to see grades" do
      RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'manage_grades', :override => false)
      RoleOverride.manage_role_override(@account, 'TeacherEnrollment', 'view_all_grades', :override => false)
      go_to_analytics("/courses/#{@course.id}/analytics")
      expect(not_found('#students')).to be
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
      expect(fj("rect.#{Time.now.utc.strftime("%Y-%m-%d")}")).to be_nil
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
      expect(find("#student_#{@student.id} .submissions")).to include_text('3')
      expect(find("#student_#{@student.id} .on_time")).to include_text('1')
      expect(find("#student_#{@student.id} .late")).to include_text('1')
      expect(find("#student_#{@student.id} .missing")).to include_text('1')
    end
  end
end
