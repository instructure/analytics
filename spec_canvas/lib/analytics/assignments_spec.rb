require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))

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

        include_examples 'basic assignment data'
      end

      describe '#base_data' do
        subject { OpenStruct.new( assignments.basic_assignment_data(assignment) ) }

        include_examples 'basic assignment data'
      end

    end

    describe '#assignment_rollups_for' do
      let(:this_course) { course }
      let(:sections) { this_course.course_sections }
      let(:section_ids) { sections.map(&:id) }
      let!(:assignment) { this_course.assignments.create!(:points_possible=>100, :due_at => Date.today) }

      before do
        3.times do
          section = this_course.course_sections.create!
          section.update_attribute(:workflow_state, 'active')
        end
        assignment.update_attribute(:workflow_state, 'active')
      end

      it 'retrieves an empty array if there is no useful data' do
        assignments = AssignmentsHarness.new(this_course)
        data = assignments.assignment_rollups_for(section_ids)
        data.should == []
      end

      it 'retrieves a hash that looks like assignments if there are rollups' do
        pending("requires the submission cached_due_at updating code")
        user = User.create!
        enrollment = StudentEnrollment.create!(:user => user, :course => this_course, :course_section => sections.first)
        Enrollment.where(:id => enrollment).update_all(:workflow_state => 'active')
        submission = assignment.submissions.create!(:user => user, :score => 95)
        submission.submitted_at = 2.days.ago
        submission.graded_at = 2.days.ago
        submission.save!

        assignments = AssignmentsHarness.new(this_course)
        data = assignments.assignment_rollups_for(section_ids)
        data.should == [{
          :assignment_id=>assignment.id, :title=>assignment.title, :due_at=>assignment.due_at,
          :muted=>assignment.muted, :points_possible=>assignment.points_possible,
          :max_score=>95, :min_score=>95, :first_quartile=>94,
          :median=>94, :third_quartile=>94, :tardiness_breakdown=>{
            :missing=>0, :late=>0, :on_time=>1, :total=>1
          }
        }]
      end
    end
  end

  class AssignmentsHarness
    include Assignments

    def initialize(course_object=nil)
      @course = course_object
    end

    def slaved(options={}); yield; end
  end

end

