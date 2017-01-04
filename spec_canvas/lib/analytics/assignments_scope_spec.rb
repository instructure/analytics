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
require_relative '../../spec_helper'
require_dependency "analytics/assignments"

module Analytics

  describe Assignments do
    let(:harness) { AssignmentsHarness.new }
    let(:course) { ::Course.create }

    describe '#assignment_scope' do
      before do
        3.times{ course.assignments.create }
        harness.instance_variable_set '@course', course
      end

      it 'should have versions included' do
        assignments = harness.assignment_scope.to_a

        expect(assignments.size).to eq 3
        assignments.each do |assignment|
          expect(assignment.versions.loaded?).to be_truthy
        end
      end

      it 'should only return published assignments' do
        unpublished_assignment = course.assignments.first
        unpublished_assignment.update_attribute(:workflow_state, 'unpublished')

        assignments = harness.assignment_scope.to_a
        expect(assignments.size).to eq 2
        expect(assignments).not_to include(unpublished_assignment)
      end
    end
  end

  class AssignmentsHarness
    include ::Analytics::Assignments
  end

end
