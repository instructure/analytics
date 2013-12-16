require File.expand_path(File.dirname(__FILE__) + '/../../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

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
        assignments = harness.assignment_scope.all

        assignments.size.should == 3
        assignments.each do |assignment|
          assignment.versions.loaded?.should be_true
        end
      end

      context 'draft_state enabled' do
        before do
          course.root_account.enable_feature!(:draft_state)
        end

        it 'should only return published assignments' do
          unpublished_assignment = course.assignments.first
          unpublished_assignment.update_attribute(:workflow_state, 'unpublished')

          assignments = harness.assignment_scope.all
          assignments.size.should == 2
          assignments.should_not include(unpublished_assignment)
        end
      end

      context 'draft_state disabled' do
        before do
          course.root_account.disable_feature!(:draft_state)
        end

        it 'should only return active assignments' do
          unpublished_assignment = course.assignments.first
          unpublished_assignment.update_attribute(:workflow_state, 'unpublished')

          assignments = harness.assignment_scope.all
          assignments.size.should == 3
          assignments.should include(unpublished_assignment)
        end
      end
    end
  end

  class AssignmentsHarness
    include Assignments
  end

end
