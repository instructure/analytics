class CachedGradeDistributions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :cached_grade_distributions, {:id => false} do |t|
      t.integer :course_id, :limit => 8, :null => false
      t.primary_key(:course_id)
      (0..100).each do |i|
        t.integer "s#{i}".to_sym, :default => 0, :null => false
      end
    end

    add_foreign_key :cached_grade_distributions, :courses, :column => :course_id
  end

  def self.down
    drop_table :cached_grade_distributions
  end
end
