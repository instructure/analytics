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

describe "analytics account view" do
  include_examples "analytics tests"

  ACCOUNT_ID = Account.default.id

  def validate_data_point(data_point, expected_count = "1")
    expect(find(".#{data_point}_count").text).to eq expected_count
  end

  before (:each) do
    enable_analytics
    course_with_admin_logged_in.user
    @course.update_attributes(:start_at => 15.days.ago, :conclude_at => 2.days.from_now)
    @course.save!
  end

  it "should validate course drop down" do
    concluded_course = Course.create!(:name => 'concluded course', :account => Account.default)
    concluded_course.offer!
    10.times do |i|
      student = User.create!(:name => "test student #{i}")
      concluded_course.enroll_user(student, 'StudentEnrollment').accept!
    end
    concluded_course.complete
    go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
    data_points = %w(courses students)
    validate_data_point(data_points[0], '1')
    validate_data_point(data_points[1], '0')
    find('.ui-combobox-next').click
    wait_for_ajaximations
    validate_data_point(data_points[0], '1')
    validate_data_point(data_points[1], '10')
  end

  context "graphs" do

    it "should validate activity by date graph with no action taken" do
      page_view_count = 10
      page_view_count.times { page_view(:user => @student, :course => @course) }
      go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
      validate_tooltip_text(date_selector(Time.now, '#participating-date-graph'), page_view_count.to_s + ' page views')
      validate_element_fill(get_rectangle(Time.now, '#participating-date-graph'), GraphColors::BLUE)
    end

    it "should validate activity by date graph with action taken" do
      page_view(:user => @student, :course => @course, :participated => true)
      expected_text = %w(1 page view 1 participation)
      go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
      expected_text.each { |text| validate_tooltip_text(date_selector(Time.now, '#participating-date-graph'), text) }
      validate_element_fill(get_rectangle(Time.now, '#participating-date-graph'), GraphColors::ORANGE)
    end

    it "should validate activity by category graph" do
      controllers = %w(files gradebook2 groups assignments)
      controllers.each { |controller| page_view(:user => @student, :course => @course, :controller => controller) }
      go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
      controllers.each { |controller| validate_tooltip_text("#participating-category-graph .#{controller}", '1 page view') }

    end

    it "should validate grade distribution graph" do
      skip('figure out how to validate this graph')
      added_students = add_students_to_course(5)
      added_students.each { |student| randomly_grade_assignments(5, student) }
      go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
      #TODO: figure out how to validate this graph
    end
  end

  context "bottom data points with all data" do

    before (:each) do
      students = add_students_to_course(1)
      assignment = @course.active_assignments.create!(:title => 'new assignment')
      assignment.submit_homework(students[0])
      topic = @course.discussion_topics.create!(:title => 'new discussion topic')
      topic.reply_from(:user => students[0], :text => 'hai')
      attachment = @course.attachments.build
      attachment.filename = "image.png"
      attachment.file_state = 'available'
      attachment.content_type = 'image/png'
      attachment.save!
      media_object = @course.media_objects.build(:media_id => 'asdf', :title => 'asdf')
      media_object.data = {:extensions => {:mp4 => {
          :size => 100,
          :extension => 'mp4'
      }}}
      media_object.save!
      go_to_analytics("/accounts/#{ACCOUNT_ID}/analytics")
    end

    %w(courses teachers students assignments topics attachments media).each do |data_point|
      it "should validate #{data_point} data point" do
        validate_data_point(data_point)
      end
    end
  end

end
