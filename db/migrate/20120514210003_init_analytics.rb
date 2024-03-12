# frozen_string_literal: true

# rubocop:disable Migration/AddIndex, Migration/RootAccountId, Migration/PrimaryKey
class InitAnalytics < ActiveRecord::Migration[7.0]
  tag :predeploy

  def up
    create_table :cached_grade_distributions, id: false do |t|
      t.primary_keys [:course_id]

      t.references :course, null: false, foreign_key: true, index: false

      101.times do |i|
        t.integer :"s#{i}", default: 0, null: false
      end
    end

    # Counts of course-related page views per category on date. participations
    # are those page views that have participated true and an associated
    # asset_user_access. The row should only exist if views (participations
    # will always be <= views) is non-zero; an absent row implies a count of
    # zero.
    create_table :page_views_rollups do |t|
      t.references :course, null: false, foreign_key: true
      t.date :date, null: false
      t.string :category, null: false, limit: 255
      t.integer :views, default: 0, null: false
      t.integer :participations, default: 0, null: false

      t.index %i[course_id date category], unique: true
    end

    add_index :scores,
              :enrollment_id,
              name: "index_scores_on_enrollment_id_no_grading_period",
              where: "grading_period_id IS NULL AND workflow_state <> 'deleted'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Migration/AddIndex, Migration/RootAccountId, Migration/PrimaryKey
