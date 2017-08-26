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

require_relative '../../../../../../spec/spec_helper'

describe PageView::Pv4Client do
  let(:client) { PageView::Pv4Client.new('http://pv4/', 'token') }

  def stub_http_request(response)
    stub = double(body: response.to_json)
    allow(CanvasHttp).to receive(:get).and_return(stub)
  end

  describe "#user_in_course_participations" do
    it "caches between requests" do
      stub = double(body: { 'participations' => [], 'page_views' => []}.to_json)
      expect(CanvasHttp).to receive(:get).once.and_return(stub)
      course = Course.create!
      user = User.create!

      expect(client.participations_for_context(course, user)).to eq []
      expect(client.counters_by_context_and_hour(course, user)).to eq({})
    end
  end

  describe "#counters_by_context_for_users" do
    it "transforms the response to a hash" do
      stub = double(body: {
          'users' => [
              { 'user_id' => 1, 'page_views' => [], 'participations' => [] },
              { 'user_id' => 2, 'page_views' => [], 'participations' => [] }
          ]
      }.to_json)
      expect(CanvasHttp).to receive(:get).and_return(stub).at_least(:once)
      course = Course.create!
      expect(client.counters_by_context_for_users(course, [])).to eq({})
      expect(client.counters_by_context_for_users(course, [1])).to eq( { 1 => { page_views: [], participations: [] }} )
      expect(client.counters_by_context_for_users(course, [1, 2])).to eq(
          { 1 => { page_views: [], participations: [] },
            2 => { page_views: [], participations: [] } }
      )
    end
  end
end
