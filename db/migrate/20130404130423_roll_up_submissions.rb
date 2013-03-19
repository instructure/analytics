class RollUpSubmissions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    AssignmentSubmissionRoller.send_later_if_production(:rollup_all)
    AssignmentsRoller.send_later_if_production(:rollup_all)
  end

  def self.down
    #no-op
  end
end
