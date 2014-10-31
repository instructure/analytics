require 'grade_distribution_cacher'

class CacheGradeDistributions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    GradeDistributionCacher.send_later_if_production(:recache_grade_distributions)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
