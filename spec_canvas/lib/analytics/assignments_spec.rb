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
require_dependency "analytics/assignments"

module Analytics

  describe Assignments do
    let(:assignments) { AssignmentsHarness.new }

    describe 'building assigment data' do
      let(:assignment) do
        double(
          :id => 2,
          :title => 'title',
          :unlock_at => '2/2/2',
          :points_possible => 5,
          :muted? => true,
          :multiple_due_dates => false,
          :grading_type => "percent",
          :submission_types => "online",
          :non_digital_submission? => false)
      end

      shared_examples_for "basic assignment data" do
        describe '#points_possible' do
          subject { super().points_possible }
          it { is_expected.to eq assignment.points_possible }
        end

        describe '#unlock_at' do
          subject { super().unlock_at }
          it { is_expected.to eq assignment.unlock_at }
        end

        describe '#assignment_id' do
          subject { super().assignment_id }
          it { is_expected.to eq assignment.id }
        end

        describe '#title' do
          subject { super().title }
          it { is_expected.to eq assignment.title }
        end
      end

      describe '#assignment_data' do

        let(:scores) { (1..5).map{|score| double(:score => score, :user_id => 123) } }

        before do
         allow(assignments).to receive(:fake_student_ids).and_return([])
         allow(assignments).to receive(:allow_student_details?).and_return(true)
        end
        subject { OpenStruct.new( assignments.assignment_data(assignment, scores) ) }

        describe '#max_score' do
          subject { super().max_score }
          it { is_expected.to eq 5 }
        end

        describe '#min_score' do
          subject { super().min_score }
          it { is_expected.to eq 1 }
        end

        describe '#muted' do
          subject { super().muted }
          it { is_expected.to be_falsey }
        end

        describe '#first_quartile' do
          subject { super().first_quartile }
          it { is_expected.to eq 1.5 }
        end

        describe '#median' do
          subject { super().median }
          it { is_expected.to eq 3 }
        end

        describe '#third_quartile' do
          subject { super().third_quartile }
          it { is_expected.to eq 4.5 }
        end

        include_examples 'basic assignment data'
      end

      describe '#base_data' do
        subject { OpenStruct.new( assignments.basic_assignment_data(assignment) ) }

        include_examples 'basic assignment data'
      end

    end

    describe '#assignment_rollups_for' do
      let(:this_course) { course_shim }
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
        expect(data).to eq []
      end

      it 'retrieves a hash that looks like assignments if there are rollups' do
        skip("requires the submission cached_due_at updating code")
        user = User.create!
        enrollment = StudentEnrollment.create!(:user => user, :course => this_course, :course_section => sections.first)
        Enrollment.where(:id => enrollment).update_all(:workflow_state => 'active')
        submission = assignment.submissions.find_or_create_by!(user: user).update! score: 95
        submission.submitted_at = 2.days.ago
        submission.graded_at = 2.days.ago
        submission.save!

        assignments = AssignmentsHarness.new(this_course)
        data = assignments.assignment_rollups_for(section_ids)
        expect(data).to eq [{
          :assignment_id=>assignment.id, :title=>assignment.title, :due_at=>assignment.due_at,
          :muted=>assignment.muted, :points_possible=>assignment.points_possible,
          :max_score=>95, :min_score=>95, :first_quartile=>94,
          :median=>94, :third_quartile=>94, :tardiness_breakdown=>{
            :missing=>0, :late=>0, :on_time=>1, :total=>1
          }
        }]
      end
    end

    describe "#assignment_scope" do
      before :once do
        course_with_student(active_all: true)
        @section_one = @course.course_sections.create!(name: "Section One")
        @section_two = @course.course_sections.create!(name: "Section Two")
        student_in_section(@section_one, user: @student)
        @assignment_one = @course.assignments.create!(title: "assignment 1")
        @assignment_two = @course.assignments.create!(title: "assignment 2")
        differentiated_assignment(assignment: @assignment_one, course_section: @section_one)
        differentiated_assignment(assignment: @assignment_two, course_section: @section_two)
        @course.reload
      end

      it "returns only visible assignments with differentiated assignments" do
        harness = AssignmentsHarness.new(@course, @student)
        expect(harness.assignment_scope.length).to eq 1
      end
    end
  end

  class AssignmentsHarness
    include ::Analytics::Assignments

    def initialize(course_object=nil, user=nil)
      @course = course_object
      @current_user = user
    end

    def slaved(options={}); yield; end
  end

end

