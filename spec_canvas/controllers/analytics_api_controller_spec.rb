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

require_relative '../../../../../spec/spec_helper'

describe AnalyticsApiController do

  let(:params) { Hash.new }
  let(:controller) { AnalyticsApiController.new }

  before do
    allow(controller).to receive_messages(:api_request? => true,
                     :require_analytics_for_course => true,
                     :render => "RENDERED!",
                     :params => params,
                     :api_v1_course_student_summaries_url => '/',
                     :session => nil)
  end

  describe '#course_student_summaries' do

    let(:course) { double(grants_any_right?: false).as_null_object }
    let(:user) { double().as_null_object }
    let(:analytics) { double(:student_summaries => ['summary1']).as_null_object }

    before do
      controller.instance_variable_set(:@current_user, user)
      controller.instance_variable_set(:@course_analytics, analytics)
      controller.instance_variable_set(:@course, course)
      allow(Api).to receive(:paginate)
    end

    describe 'when the user can manage_grades' do
      before do
        expect(course).to receive(:grants_any_right?).with(user, nil, :manage_grades, :view_all_grades).and_return(true)
      end

      it 'renders the json' do
        expect(controller.course_student_summaries).to eq "RENDERED!"
      end

      it 'passes a sort_column down to the analytics engine' do
        params[:sort_column] = 'score'
        expect(analytics).to receive(:student_summaries).with(sort_column: 'score', student_ids: nil)
        controller.course_student_summaries
      end

      it 'passes a student_id down to the analytics engine' do
        params[:student_id] = '123'
        expect(analytics).to receive(:student_summaries).with(sort_column: nil, student_ids: ['123'])
        controller.course_student_summaries
      end

      it 'paginates the summaries' do
        expect(Api).to receive(:paginate).with(['summary1'], controller, '/')
        controller.course_student_summaries
      end
    end

    describe 'when the user has no grades permissions' do
      it 'does not render the json' do
        expect(controller).to receive(:render_unauthorized_action)
        expect(controller.course_student_summaries).not_to eq "RENDERED!"
      end
    end

  end
end
