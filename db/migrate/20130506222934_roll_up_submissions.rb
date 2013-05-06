class RollUpSubmissions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    (1..12).each do |month_index|
      start_at = month_index.months.ago
      end_at = start_at + 1.month
      AssignmentSubmissionRoller.send_later_if_production_enqueue_args(:rollup_all,
        {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1, :n_strand => "rollup_submissions_migration"},
        {:start_at => start_at, :end_at => end_at})
    end

    AssignmentsRoller.send_later_if_production_enqueue_args(:rollup_all,
        {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1, :n_strand => "rollup_assignments_migration"})
  end

  def self.down
    #no-op
  end
end
