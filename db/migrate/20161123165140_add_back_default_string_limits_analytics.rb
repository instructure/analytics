class AddBackDefaultStringLimitsAnalytics < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    add_string_limit_if_missing :page_views_rollups, :category
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
