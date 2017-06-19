class FixCachedGradeDistributionsColumnType < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    unless column_exists?(:cached_grade_distributions, :course_id, :integer, limit: 8)
      change_column :cached_grade_distributions, :course_id, :integer, limit: 8, null: false, primary_key: true
    end
  end
end
