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

require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AnalyticsApiController do

  let(:params) { Hash.new }
  let(:controller) { AnalyticsApiController.new }

  before do
    controller.stubs(:api_request? => true,
                     :require_analytics_for_course => true,
                     :render => "RENDERED!",
                     :params => params,
                     :api_v1_course_student_summaries_url => '/',
                     :session => nil)
  end

  describe '#course_student_summaries' do

    let(:course) { stub_everything() }
    let(:user) { stub_everything() }
    let(:analytics) { stub_everything(:student_summaries => ['summary1']) }

    before do
      controller.instance_variable_set(:@current_user, user)
      controller.instance_variable_set(:@course_analytics, analytics)
      controller.instance_variable_set(:@course, course)
      Api.stubs(:paginate)
    end

    describe 'when the user can manage_grades' do
      before do
        controller.expects(:is_authorized_action?).with(course, user, includes(:manage_grades)).returns(true)
      end

      it 'renders the json' do
        controller.course_student_summaries.should == "RENDERED!"
      end

      it 'passes a sort_column down to the analytics engine if one is present' do
        params[:sort_column] = 'score'
        analytics.expects(:student_summaries).with('score')
        controller.course_student_summaries
      end

      it 'paginates the summaries' do
        Api.expects(:paginate).with(['summary1'], controller, '/')
        controller.course_student_summaries
      end
    end

    describe 'when the user can view_all_grades' do
      before do
        controller.expects(:is_authorized_action?).with(course, user, includes(:view_all_grades)).returns(true)
      end

      it 'renders the json' do
        controller.course_student_summaries.should == "RENDERED!"
      end
    end

    describe 'when the user has no grades permissions' do
      it 'does not render the json' do
        controller.expects(:render_unauthorized_action)
        controller.course_student_summaries.should_not == "RENDERED!"
      end
    end

  end
end
