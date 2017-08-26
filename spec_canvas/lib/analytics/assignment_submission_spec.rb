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

        allow(assignment_submission).to receive(:recorded_at).and_return(nil)
        expect(assignment_submission.recorded?).to be_falsey

        allow(assignment_submission).to receive(:recorded_at).and_return(date)
        expect(assignment_submission.recorded?).to be_truthy
      end

      context "recorded_at" do
        it "should return nil when missing" do
          allow(submission).to receive(:missing?).and_return(true)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to be_nil
        end

        it "should return submitted_at when present" do
          allow(submission).to receive(:submitted_at).and_return(date)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return submitted_at when not graded" do
          allow(submission).to receive(:submitted_at).and_return(date)
          allow(submission).to receive(:graded?).and_return(false)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return nil when graded_at is nil and not graded nor submitted" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          allow(assignment_submission).to receive(:graded?).and_return(true)
          allow(assignment_submission).to receive(:graded_at).and_return(nil)
          allow(assignment_submission).to receive(:due_at).and_return(date)

          expect(assignment_submission.recorded_at).to be_nil
        end

        it "should return graded_at when due_at does not exist" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          allow(assignment_submission).to receive(:graded?).and_return(true)
          allow(assignment_submission).to receive(:graded_at).and_return(date)
          allow(assignment_submission).to receive(:due_at).and_return(nil)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return due_at when due_at is before graded_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          allow(assignment_submission).to receive(:graded?).and_return(true)
          allow(assignment_submission).to receive(:due_at).and_return(date)
          allow(assignment_submission).to receive(:graded_at).and_return(date + 2.days)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return graded_at when graded_at is before due_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          allow(assignment_submission).to receive(:graded?).and_return(true)
          allow(assignment_submission).to receive(:due_at).and_return(date + 2.days)
          allow(assignment_submission).to receive(:graded_at).and_return(date)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return graded_at when its not passed the due date and graded at a grade greater than zero" do
          allow(submission).to receive(:graded?).and_return(true)
          allow(submission).to receive(:graded_at).and_return(date)
          allow(submission).to receive(:score).and_return(10)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          allow(assignment_submission).to receive(:due_at).and_return(date + 2.days)

          expect(assignment_submission.recorded_at).to eq date
        end

        it "should return nil when its not passed the due date and graded at a grade of zero" do
          allow(submission).to receive(:graded?).and_return(true)
          allow(submission).to receive(:graded_at).and_return(date)
          allow(submission).to receive(:score).and_return(0)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          allow(assignment_submission).to receive(:due_at).and_return(date + 2.days)

          expect(assignment_submission.recorded_at).to be_nil
        end
      end

      it "should return cached due_date" do
        allow(submission).to receive(:cached_due_date).and_return(Time.now)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.due_at).to eq submission.cached_due_date.change(sec: 0)
      end

      it "should return missing?" do
        allow(submission).to receive(:missing?).and_return(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.missing?).to be_truthy
      end

      it "should return late?" do
        allow(submission).to receive(:late?).and_return(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.late?).to be_truthy
      end

      it "should return on_time?" do
        allow(submission).to receive(:submitted_at).and_return(2.days.ago)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.on_time?).to be_truthy
      end

      it "should return floating?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.floating?).to be_truthy
      end

      it "should return status" do
        allow(submission).to receive(:missing?).and_return(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.status).to eq :missing
      end

      it "should return score" do
        score = 10
        allow(submission).to receive(:score).and_return(score)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.score).to eq score
      end

      it "should return submitted_at" do
        allow(submission).to receive(:submitted_at).and_return(date)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        expect(assignment_submission.submitted_at).to eq date
      end

      it "should return graded?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)

        allow(submission).to receive(:graded?).and_return(true)
        expect(assignment_submission.graded?).to be_truthy

        allow(submission).to receive(:graded?).and_return(false)
        expect(assignment_submission.graded?).to be_falsey
      end

      it "should return graded_at" do
        allow(submission).to receive(:graded_at).and_return(date)

        assignment_submission = AssignmentSubmission.new(assignment, submission)

        allow(assignment_submission).to receive(:graded?).and_return(true)
        expect(assignment_submission.graded_at).to eq date

        allow(assignment_submission).to receive(:graded?).and_return(false)
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
        allow(assignment).to receive(:overdue?).and_return(true)
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
