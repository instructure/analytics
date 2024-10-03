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
  describe Assignments do
    let(:harness) { AssignmentsHarness.new }
    let(:course) { ::Course.create }

    describe "#assignment_scope" do
      before do
        3.times { course.assignments.create }

        assignment = course.assignments.last

        assignment.sub_assignments.create!(
          title: "Test",
          context: assignment.context,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
        )

        harness.instance_variable_set :@course, course
      end

      it "has versions included" do
        assignments = harness.assignment_scope.to_a

        expect(assignments.size).to eq 4
        assignments.each do |assignment|
          expect(assignment.versions.loaded?).to be_truthy
        end
      end

      it "only returns published assignments" do
        unpublished_assignment = course.assignments.first
        unpublished_assignment.update_attribute(:workflow_state, "unpublished")

        assignments = harness.assignment_scope.to_a
        expect(assignments.size).to eq 3
        expect(assignments).not_to include(unpublished_assignment)
      end
    end
  end

  class AssignmentsHarness
    include ::Analytics::Assignments
  end
end
