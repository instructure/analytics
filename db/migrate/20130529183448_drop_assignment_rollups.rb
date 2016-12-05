class DropAssignmentRollups < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :assignment_rollups
  end

  def self.down
    create_table :assignment_rollups do |t|
      t.integer  :assignment_id,     :limit => 8,   :null => false
      t.integer  :course_section_id, :limit => 8
      t.datetime :due_at
      t.string   :title,                            :null => false
      t.boolean  :muted
      t.float    :max_score
      t.float    :first_quartile_score
      t.float    :median_score
      t.float    :third_quartile_score
      t.float    :min_score
      t.float    :points_possible
      t.integer  :total_submissions
      t.float    :late_submissions
      t.float    :missing_submissions
      t.float    :on_time_submissions
      t.text     :score_buckets
    end
    add_index :assignment_rollups, [:assignment_id]
    add_index :assignment_rollups, [:course_section_id]
    add_foreign_key :assignment_rollups, :assignments, :column => :assignment_id
  end
end
