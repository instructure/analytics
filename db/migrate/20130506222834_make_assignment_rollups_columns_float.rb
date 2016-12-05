class MakeAssignmentRollupsColumnsFloat < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :assignment_rollups, :max_score, :float
    change_column :assignment_rollups, :median_score, :float
    change_column :assignment_rollups, :min_score, :float
    change_column :assignment_rollups, :points_possible, :float
  end

  def self.down
    change_column :assignment_rollups, :max_score, :integer
    change_column :assignment_rollups, :median_score, :integer
    change_column :assignment_rollups, :min_score, :integer
    change_column :assignment_rollups, :points_possible, :integer
  end
end
