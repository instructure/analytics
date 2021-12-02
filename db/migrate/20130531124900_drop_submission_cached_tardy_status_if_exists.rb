# frozen_string_literal: true

class DropSubmissionCachedTardyStatusIfExists < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    if connection.columns(:submissions).map(&:name).include?("cached_tardy_status")
      remove_column :submissions, :cached_tardy_status
    end
  end
end
