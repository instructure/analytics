require File.expand_path('../../../../../../spec/spec_helper', File.dirname(__FILE__))

module Analytics
  describe AssignmentSubmission do
    let(:assignment) { ::Assignment.create!({ :context => course }) }
    let(:date) { Time.now.change(usec: 0) }

    context "with submission" do
      let(:submission) { assignment.submissions.create!(:user => user) }

      it "should return recorded" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)

        assignment_submission.stubs(:recorded_at).returns(nil)
        assignment_submission.recorded?.should be_false

        assignment_submission.stubs(:recorded_at).returns(date)
        assignment_submission.recorded?.should be_true
      end

      context "recorded_at" do
        it "should return nil when missing" do
          submission.stubs(:missing?).returns(true)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.recorded_at.should be_nil
        end

        it "should return submitted_at when present" do
          submission.stubs(:submitted_at).returns(date)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.recorded_at.should == date
        end

        it "should return submitted_at when not graded" do
          submission.stubs(:submitted_at).returns(date)
          submission.stubs(:graded?).returns(false)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.recorded_at.should == date
        end

        it "should return nil when graded_at is nil and not graded nor submitted" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:graded_at).returns(nil)
          assignment_submission.stubs(:due_at).returns(date)

          assignment_submission.recorded_at.should be_nil
        end

        it "should return graded_at when due_at does not exist" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:graded_at).returns(date)
          assignment_submission.stubs(:due_at).returns(nil)

          assignment_submission.recorded_at.should == date
        end

        it "should return due_at when due_at is before graded_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:due_at).returns(date)
          assignment_submission.stubs(:graded_at).returns(date + 2.days)

          assignment_submission.recorded_at.should == date
        end

        it "should return graded_at when graded_at is before due_at" do
          assignment_submission = AssignmentSubmission.new(assignment, submission)

          assignment_submission.stubs(:graded?).returns(true)
          assignment_submission.stubs(:due_at).returns(date + 2.days)
          assignment_submission.stubs(:graded_at).returns(date)

          assignment_submission.recorded_at.should == date
        end

        it "should return graded_at when its not passed the due date and graded at a grade greater than zero" do
          submission.stubs(:graded?).returns(true)
          submission.stubs(:graded_at).returns(date)
          submission.stubs(:score).returns(10)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.stubs(:due_at).returns(date + 2.days)

          assignment_submission.recorded_at.should == date
        end

        it "should return nil when its not passed the due date and graded at a grade of zero" do
          submission.stubs(:graded?).returns(true)
          submission.stubs(:graded_at).returns(date)
          submission.stubs(:score).returns(0)

          assignment_submission = AssignmentSubmission.new(assignment, submission)
          assignment_submission.stubs(:due_at).returns(date + 2.days)

          assignment_submission.recorded_at.should be_nil
        end
      end

      it "should return cached due_date" do
        submission.cached_due_date = Time.now

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.due_at.should == submission.cached_due_date
      end

      it "should return missing?" do
        submission.stubs(:missing?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.missing?.should be_true
      end

      it "should return late?" do
        submission.stubs(:late?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.late?.should be_true
      end

      it "should return on_time?" do
        submission.stubs(:submitted_at).returns(2.days.ago)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.on_time?.should be_true
      end

      it "should return floating?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.floating?.should be_true
      end

      it "should return status" do
        submission.stubs(:missing?).returns(true)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.status.should == :missing
      end

      it "should return score" do
        score = 10
        submission.stubs(:score).returns(score)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.score.should == score
      end

      it "should return submitted_at" do
        submission.stubs(:submitted_at).returns(date)

        assignment_submission = AssignmentSubmission.new(assignment, submission)
        assignment_submission.submitted_at.should == date
      end

      it "should return graded?" do
        assignment_submission = AssignmentSubmission.new(assignment, submission)

        submission.stubs(:graded?).returns(true)
        assignment_submission.graded?.should be_true

        submission.stubs(:graded?).returns(false)
        assignment_submission.graded?.should be_false
      end

      it "should return graded_at" do
        submission.graded_at = date

        assignment_submission = AssignmentSubmission.new(assignment, submission)

        assignment_submission.stubs(:graded?).returns(true)
        assignment_submission.graded_at.should == date

        assignment_submission.stubs(:graded?).returns(false)
        assignment_submission.graded_at.should be_nil
      end
    end

    context "without submission" do
      let(:assignment_submission) { AssignmentSubmission.new(assignment) }

      it "should return recorded" do
        assignment_submission.recorded?.should be_false
      end

      it "should return recorded_at" do
        assignment_submission.recorded_at.should be_nil
      end

      it "should return assignment due_at" do
        assignment_submission.due_at.should == assignment.due_at
      end

      it "should return missing?" do
        assignment_submission.missing?.should be_false
      end

      it "should return late?" do
        assignment_submission.late?.should be_false
      end

      it "should return on_time?" do
        assignment_submission.on_time?.should be_false
      end

      it "should return floating?" do
        assignment_submission.floating?.should be_true
      end

      it "should return floating status" do
        assignment_submission.status.should == :floating
      end

      it "should return missing status when assignment overdue" do
        assignment.stubs(:overdue?).returns(true)
        AssignmentSubmission.new(assignment).status.should == :missing
      end

      it "should return score" do
        assignment_submission.score.should be_nil
      end

      it "should return submitted_at" do
        assignment_submission.submitted_at.should be_nil
      end

      it "should return graded?" do
        assignment_submission.graded?.should be_nil
      end

      it "should return graded_at" do
        assignment_submission.graded_at.should be_nil
      end
    end
  end
end