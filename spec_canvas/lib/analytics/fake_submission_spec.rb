#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'spec_helper'

describe Analytics::FakeSubmission do
  before(:once) do
    @course = Course.create!
    @student = @course.enroll_student(User.create!, enrollment_state: :active)
    @assignment = @course.assignments.create!(submission_types: "online_text_entry")
  end

  let(:late_fake_submission) do
    now = Time.zone.now
    due_at = 2.hours.ago(now)
    submission = Analytics::FakeSubmission.new(
      "assignment_id" => @assignment.id,
      "user_id" => @student.id,
      "cached_due_date" => due_at,
      "submission_type" => "online_upload",
      "submitted_at" => now
    )
    submission.assignment = @assignment
    submission
  end

  let(:on_time_fake_submission) do
    due_at = 2.hours.ago
    submission = Analytics::FakeSubmission.new(
      "assignment_id" => @assignment.id,
      "user_id" => @student.id,
      "cached_due_date" => due_at,
      "submission_type" => "online_upload",
      "submitted_at" => due_at
    )
    submission.assignment = @assignment
    submission
  end

  it ".from_scope creates a FakeSubmission from each submission returned by the scope" do
    submissions_from_scope = Analytics::FakeSubmission.from_scope(@course.submissions)
    expect(submissions_from_scope.first).to be_a Analytics::FakeSubmission
  end

  describe "#excused?" do
    it "returns true if the submission is excused" do
      submission = Analytics::FakeSubmission.new("excused" => true)
      expect(submission).to be_excused
    end

    it "returns false if the submission is not excused" do
      submission = Analytics::FakeSubmission.new("excused" => false)
      expect(submission).not_to be_excused
    end
  end

  describe "#graded?" do
    it "returns true if the submission has a score and workflow state is 'graded'" do
      submission = Analytics::FakeSubmission.new("score" => 5.0, "workflow_state" => "graded")
      expect(submission).to be_graded
    end

    it "returns true if the submission is excused" do
      submission = Analytics::FakeSubmission.new("excused" => true)
      expect(submission).to be_graded
    end

    it "returns false if the submission is not graded" do
      submission = Analytics::FakeSubmission.new({})
      expect(submission).not_to be_graded
    end
  end

  describe "#late?" do
    it "returns true if submitted and past due" do
      expect(late_fake_submission).to be_late
    end

    it "returns false if submitted on time" do
      expect(on_time_fake_submission).not_to be_late
    end
  end

  describe "#past_due?" do
    it "returns true if submitted and past due" do
      expect(late_fake_submission).to be_past_due
    end

    it "returns false if submitted on time" do
      expect(on_time_fake_submission).not_to be_past_due
    end
  end

  describe "#seconds_late" do
    it "returns the number of seconds late a submission is" do
      expect(late_fake_submission.seconds_late).to be 7200
    end

    it "returns the overridden seconds late if late_policy_status is 'late'" do
      submission = Analytics::FakeSubmission.new("late_policy_status" => "late", "seconds_late_override" => 25)
      expect(submission.seconds_late).to be 25
    end
  end

  describe "#missing?" do
    it "returns true if not submitted and past due" do
      due_at = 3.weeks.ago
      submission = Analytics::FakeSubmission.new(
        "assignment_id" => @assignment.id,
        "user_id" => @student.id,
        "cached_due_date" => due_at,
        "submission_type" => "online_upload"
      )
      submission.assignment = @assignment

      expect(submission).to be_missing
    end

    it "returns false if submitted and past due" do
      expect(late_fake_submission).not_to be_missing
    end
  end

  it "sets submitted_at to nil if there is no submission_type" do
    submission = Analytics::FakeSubmission.new("submitted_at" => 2.days.ago)
    expect(submission.submitted_at).to be_nil
  end
end
