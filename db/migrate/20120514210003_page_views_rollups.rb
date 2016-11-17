class PageViewsRollups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # Counts of course-related page views per category on date. participations
    # are those page views that have participated true and an associated
    # asset_user_access. The row should only exist if views (participations
    # will always be <= views) is non-zero; an absent row implies a count of
    # zero.
    create_table :page_views_rollups do |t|
      t.integer  :course_id,      :limit => 8,   :null => false
      t.date     :date,                          :null => false
      t.string   :category,                      :null => false
      t.integer  :views,          :default => 0, :null => false
      t.integer  :participations, :default => 0, :null => false
    end
    add_index :page_views_rollups, [:course_id, :date, :category]
    add_index :page_views_rollups, [:course_id]

    add_foreign_key :page_views_rollups, :courses, :column => :course_id
  end

  def self.down
    drop_table :page_views_rollups
  end
end
