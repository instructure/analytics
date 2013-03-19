require File.expand_path(File.dirname(__FILE__) + '/../../../../../spec/spec_helper')

describe AssignmentSubmissionRoller do
  describe '#rollup_all' do
    let(:current_course) { course }
    let(:assignment) { Assignment.create!(:context => current_course, :due_at => 12.days.ago) }
    let(:user) { User.create! }
    let(:submission) { Submission.create!(:assignment => assignment, :user => user, :submission_type => 'online_url') }


    it 'caches the tardy status' do
      submission.submitted_at = 13.days.ago
      submission.save!
      AssignmentSubmissionRoller.rollup_all
      submission.reload.cached_tardy_status.should == 'on_time'
    end

    describe 'time range' do
      let(:other_user) { User.create! }

      let!(:old_submission) do
        sub = Submission.create!(:assignment => assignment, :user => other_user, :submission_type => 'online_url')
        Submission.record_timestamps = false
        sub.update_attribute(:submitted_at, 900.days.ago)
        sub.update_attribute(:created_at, 874.days.ago)
        sub.update_attribute(:updated_at, 873.days.ago)
        Submission.record_timestamps = true
        sub
      end

      it 'grabs submissions modified in the last 2 years by default' do
        lambda{ AssignmentSubmissionRoller.rollup_all }.should_not change { old_submission.reload.updated_at }
      end

      it 'can be overriden to cache submissions farther back' do
        AssignmentSubmissionRoller.rollup_all(:start_at => 3.years.ago)
        old_submission.reload.cached_tardy_status.should_not be_nil
      end
    end
  end
end
