require 'mocha/api'
require 'active_support/core_ext'
require File.expand_path('../../../../../../lib/stats', File.dirname(__FILE__))
require File.expand_path('../../../lib/analytics/assignments', File.dirname(__FILE__))

module Analytics

  describe Assignments do
    let(:assignments) { AssignmentsHarness.new }

    describe 'building assigment data' do
      let(:assignment) do
        stub(
          :id => 2,
          :title => 'title',
          :unlock_at => '2/2/2',
          :points_possible => 5,
          :muted? => true,
          :multiple_due_dates => false) 
      end

      shared_examples_for "basic assignment data" do
        its(:points_possible) { should == assignment.points_possible }
        its(:unlock_at) { should == assignment.unlock_at }
        its(:assignment_id) { should == assignment.id }
        its(:title) { should == assignment.title }
      end

      describe '#assignment_data' do

        let(:scores) { (1..5).map{|score| stub(:score => score) } }

        before { assignments.stubs(:allow_student_details? => true) }
        subject { OpenStruct.new( assignments.assignment_data(assignment, scores) ) }

        its(:max_score) { should == 5 }
        its(:min_score) { should == 1 }
        its(:muted) { should be_false }
        its(:first_quartile) { should == 1.5 }
        its(:median) { should == 3 }
        its(:third_quartile) { should == 4.5 }

        it_should_behave_like 'basic assignment data'
      end

      describe '#base_data' do
        subject { OpenStruct.new( assignments.basic_assignment_data(assignment) ) }

        it_should_behave_like 'basic assignment data'
      end

    end
  end

  class AssignmentsHarness
    include Assignments
  end

end

