#
# Copyright (C) 2015 Instructure, Inc.
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
require_dependency "analytics/assignment_rollup"

module Analytics
  describe AssignmentRollup do
    describe "build" do
      # pending 'merge of https://gerrit.instructure.com/c/120358/'
      # it "does not work with a missing external tool assignment" do
      #   assignment_model(due_at: 1.day.ago, submission_types: "external_tool")
      #   submission_model(assignment: @assignment, submitted_at: nil)
      #   rollup = AssignmentRollup.build(@course, @assignment)
      #   rollup = rollup[@course.default_section.id]
      #   expect(rollup.missing_submissions).to eql(0.0)
      # end
    end
  end
end
