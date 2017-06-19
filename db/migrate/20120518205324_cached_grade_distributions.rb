class CachedGradeDistributions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :cached_grade_distributions, id: false do |t|
      t.integer :course_id, limit: 8, null: false, primary_key: true
      (0..100).each do |i|
        t.integer "s#{i}".to_sym, default: 0, null: false
      end
    end

    add_foreign_key :cached_grade_distributions, :courses
  end

  def down
    drop_table :cached_grade_distributions
  end
end
