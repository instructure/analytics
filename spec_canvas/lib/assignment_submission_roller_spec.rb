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
      def build_submission_for(days_ago)
        sub = Submission.create!(:assignment => assignment, :user => User.create!, :submission_type => 'online_url')
        Submission.record_timestamps = false
        sub.update_attribute(:submitted_at, days_ago.days.ago)
        sub.update_attribute(:created_at, days_ago.days.ago)
        sub.update_attribute(:updated_at, days_ago.days.ago)
        Submission.record_timestamps = true
        Submission.update_all('cached_tardy_status = NULL', "id = #{sub.id}")
        sub
      end

      let!(:old_submission) { build_submission_for(900) }
      let!(:less_old_submission) { build_submission_for(800) }

      it 'grabs submissions modified in the last 2 years by default' do
        lambda{ AssignmentSubmissionRoller.rollup_all }.should_not change { old_submission.reload.updated_at }
      end

      it 'can be overriden to cache submissions farther back' do
        AssignmentSubmissionRoller.rollup_all(:start_at => 3.years.ago)
        old_submission.reload.cached_tardy_status.should_not be_nil
        less_old_submission.reload.cached_tardy_status.should_not be_nil
      end

      it 'can target a specific window' do
        old_submission.reload.cached_tardy_status.should be_nil
        AssignmentSubmissionRoller.rollup_all(:start_at => 820.days.ago, :end_at => 780.days.ago)
        old_submission.reload.cached_tardy_status.should be_nil
        less_old_submission.reload.cached_tardy_status.should_not be_nil
      end
    end
  end
end
