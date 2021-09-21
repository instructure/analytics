# frozen_string_literal: true

class AddScoresIndexForGradeDistributions < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :scores, :enrollment_id, name: "index_scores_on_enrollment_id_no_grading_period",
                                       where: "grading_period_id IS NULL AND workflow_state <> 'deleted'", algorithm: :concurrently
  end
end
