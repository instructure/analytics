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
require_dependency "analytics/assignment_submission"

module Analytics
  describe AssignmentSubmission do
    let(:assignment) { ::Assignment.create!({ :context => course_shim }) }
    let(:date) { Time.now.change(sec: 0) }

    context "with submission" do
      let(:submission) do
        submission = FakeSubmission.new(assignment_id: assignment.id, user_id: user_factory.id)
        submission.assignment = assignment
        submission
      end

      it "should return recorded" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)

        assignment_submission.stubs(:recorded_at).returns(nil)
        expect(assignment_submission.recorded?).to be_falsey

        assignment_submission.stubs(:recorded_at).returns(date)
        expect(assignment_submission.recorded?).to be_truthy
      end

      context "recorded_at" do
        it "should return nil when missing" do
          submission.stubs(:missing?).returns(true)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to be_nil
        end

        it "should return submitted_at when present" do
          submission.stubs(:submitted_at).returns(date)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return submitted_at when not graded" do
          submission.stubs(:submitted_at).returns(date)
          submission.stubs(:graded?).returns(false)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return nil when graded_at is nil and not graded nor submitted" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:graded_at).returns(nil)
          assignment_submission.stubs(:due_at).returns(date)

          expect(assignment_submission.recorded_at).to be_nil
        end

        it "should return graded_at when due_at does not exist" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:graded_at).returns(date)
          assignment_submission.stubs(:due_at).returns(nil)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return due_at when due_at is before graded_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:due_at).returns(date)
          assignment_submission.stubs(:graded_at).returns(date + 2.days)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return graded_at when graded_at is before due_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:due_at).returns(date + 2.days)
          assignment_submission.stubs(:graded_at).returns(date)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return graded_at when its not passed the due date and graded at a grade greater than zero" do
          submission.stubs(:graded?).returns(true)
          submission.stubs(:graded_at).returns(date)
          submission.stubs(:score).returns(10)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.stubs(:due_at).returns(date + 2.days)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return nil when its not passed the due date and graded at a grade of zero" do
          submission.stubs(:graded?).returns(true)
          submission.stubs(:graded_at).returns(date)
          submission.stubs(:score).returns(0)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.stubs(:due_at).returns(date + 2.days)

          expect(assignment_submission.recorded_at).to be_nil
        end
      end

      it "should return cached due_date" do
        submission.stubs(:cached_due_date).returns(Time.now)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.due_at).to eq submission.cached_due_date.change(sec: 0)
      end

      it "should return missing?" do
        submission.stubs(:missing?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.missing?).to be_truthy
      end

      it "should return late?" do
        submission.stubs(:late?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.late?).to be_truthy
      end

      it "should return on_time?" do
        submission.stubs(:submitted_at).returns(2.days.ago)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.on_time?).to be_truthy
      end

      it "should return floating?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.floating?).to be_truthy
      end

      it "should return status" do
        submission.stubs(:missing?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.status).to eq :missing
      end

      it "should return score" do
        score = 10
        submission.stubs(:score).returns(score)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.score).to eq score
      end

      it "should return submitted_at" do
        submission.stubs(:submitted_at).returns(date)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.submitted_at).to eq date
      end

      it "should return graded?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)

        submission.stubs(:graded?).returns(true)
        expect(assignment_submission.graded?).to be_truthy

        submission.stubs(:graded?).returns(false)
        expect(assignment_submission.graded?).to be_falsey
      end

      it "should return graded_at" do
        submission.stubs(:graded_at).returns(date)

        assignment_submission = AssignmentSubmission.new(assignment, submission)

        assignment_submission.stubs(:graded?).returns(true)
        expect(assignment_submission.graded_at).to eq date

        assignment_submission.stubs(:graded?).returns(false)
        expect(assignment_submission.graded_at).to be_nil
      end
    end

    context "without submission" do
      let(:assignment_submission) { AssignmentSubmission.new(assignment) }

      it "should return recorded" do
        expect(assignment_submission.recorded?).to be_falsey
      end

      it "should return recorded_at" do
        expect(assignment_submission.recorded_at).to be_nil
      end

      it "should return assignment due_at" do
        expect(assignment_submission.due_at).to eq assignment.due_at&.change(sec: 0)
      end

      it "should return missing?" do
        expect(assignment_submission.missing?).to be_falsey
      end

      it "should return late?" do
        expect(assignment_submission.late?).to be_falsey
      end

      it "should return on_time?" do
        expect(assignment_submission.on_time?).to be_falsey
      end

      it "should return floating?" do
        expect(assignment_submission.floating?).to be_truthy
      end

      it "should return floating status" do
        expect(assignment_submission.status).to eq :floating
      end

      it "should return missing status when assignment overdue" do
        assignment.stubs(:overdue?).returns(true)
        expect(AssignmentSubmission.new(assignment).status).to eq :missing
      end

      it "should return score" do
        expect(assignment_submission.score).to be_nil
      end

      it "should return submitted_at" do
        expect(assignment_submission.submitted_at).to be_nil
      end

      it "should return graded?" do
        expect(assignment_submission.graded?).to be_nil
      end

      it "should return graded_at" do
        expect(assignment_submission.graded_at).to be_nil
      end
    end
  end
end
