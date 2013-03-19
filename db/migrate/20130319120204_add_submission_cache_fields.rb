class AddSubmissionCacheFields < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :submissions, :cached_tardy_status, :string
    add_column :submissions, :cached_due_date, :datetime
  end

  def self.down
    remove_column :submissions, :cached_tardy_status
    remove_column :submissions, :cached_due_date
  end
end
