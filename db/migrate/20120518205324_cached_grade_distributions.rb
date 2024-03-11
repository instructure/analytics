# frozen_string_literal: true

class CachedGradeDistributions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :cached_grade_distributions, id: false do |t|
      t.bigint :course_id, null: false, primary_key: true
      101.times do |i|
        t.integer :"s#{i}", default: 0, null: false
      end
    end

    add_foreign_key :cached_grade_distributions, :courses
  end

  def down
    drop_table :cached_grade_distributions
  end
end
