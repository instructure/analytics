class RollupPageViews < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    PageViewRoller.send_later_if_production(:rollup_all)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
