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

require_relative '../../../../spec/cassandra_spec_helper'

shared_examples_for "analytics cassandra page views" do
  include_examples "cassandra page views"
  before do
    if Canvas::Cassandra::DatabaseBuilder.configured?('page_views')
      PageView::EventStream.database.execute("TRUNCATE page_views_counters_by_context_and_user")
      PageView::EventStream.database.execute("TRUNCATE page_views_counters_by_context_and_hour")
      PageView::EventStream.database.execute("TRUNCATE participations_by_context")
    end
  end
end
