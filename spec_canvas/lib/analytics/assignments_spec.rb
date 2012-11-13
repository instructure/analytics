require 'mocha'
require 'active_support/core_ext'
require File.expand_path('../../../../../../lib/stats', File.dirname(__FILE__))
require File.expand_path('../../../lib/analytics/assignments', File.dirname(__FILE__))

module Analytics

  describe Assignments do
    let(:assignments) { AssignmentsHarness.new }

    describe '#submission_date' do
      let(:submitted_at_date) { 2.days.ago }
      let(:graded_at_date) { 3.days.ago }
      let(:due_at_date) { 4.days.ago }
      let(:assignment) { stub(:due_at => due_at_date, :submittable_type? => false ) }
      let(:submission_attrs) { { :submitted_at => nil, :graded_at => graded_at_date, :graded? => false } }

      def build_submission(attrs={})
        stub( submission_attrs.merge(attrs) )
      end

      it 'uses the submitted_at date if its available' do
        submission = build_submission( :submitted_at => submitted_at_date )
        assignments.submission_date(assignment, submission).should == submitted_at_date
      end

      it 'uses the graded date when no submission date and the submission has not been graded' do
        submission = build_submission
        assignments.submission_date(assignment, submission).should == graded_at_date
      end

      it 'uses the assignment due date when there is no submission date and the submission has not been graded' do
        submission = build_submission( :graded? => true )
        assignments.submission_date(assignment, submission).should == due_at_date
      end
    end

    describe 'building assigment data' do
      let(:assignment) { stub(:id => 2, :title => 'title', :due_at => '1/1/1', :unlock_at => '2/2/2', :points_possible => 5, :muted? => true) }

      shared_examples_for "Basic assignment data" do
        its(:points_possible) { should == assignment.points_possible }
        its(:due_at) { should == assignment.due_at }
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

        it_should_behave_like 'Basic assignment data'
      end

      describe '#base_data' do
        subject { OpenStruct.new( assignments.basic_assignment_hash(assignment) ) }

        it_should_behave_like 'Basic assignment data'
      end

    end
  end

  class AssignmentsHarness
    include Assignments
  end

end

