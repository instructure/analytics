class FixCachedGradeDistributionsSequence < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # postgres creates a sequence for the "primary key"
    return unless connection.adapter_name == 'PostgreSQL'
    change_column_default(:cached_grade_distributions, :course_id, nil)
    execute("DROP SEQUENCE IF EXISTS #{connection.quote_table_name('cached_grade_distributions_course_id_seq')}")
  end
end
