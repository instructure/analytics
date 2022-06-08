# frozen_string_literal: true

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

module Analytics
  describe StudentSummary do
    describe "#tardiness_breakdown" do
      it "serves a blank hash for a missing student id" do
        student = double(id: 42)
        course = double(tardiness_breakdowns: { students: {} })
        page_view_counts = double
        analysis = double
        summary = StudentSummary.new(student, course, page_view_counts, analysis)
        expect(summary.tardiness_breakdown).to eq({})
      end
    end
  end
end
