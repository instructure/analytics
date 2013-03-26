require File.expand_path(File.dirname(__FILE__) + '/../../../../../../spec/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Analytics

  describe Assignments do
    let(:harness) { AssignmentsHarness.new }

    describe '#assignment_scope' do
      it 'should have versions included' do
        course = ::Course.create
        3.times{ course.assignments.create }

        harness.instance_variable_set '@course', course

        assignments = harness.assignment_scope.all
        assignments.size.should == 3
        assignments.each do |assignment|
          assignment.versions.loaded?.should be_true
        end
      end
    end
  end

  class AssignmentsHarness
    include Assignments
  end

end
