class DropSubmissionCachedTardyStatusIfExists < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    if self.connection.columns(:submissions).map(&:name).include?('cached_tardy_status')
      remove_column :submissions, :cached_tardy_status
    end
  end

  def self.down
  end
end
