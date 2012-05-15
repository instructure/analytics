Course.class_eval do
  has_one :cached_grade_distribution
  has_many :page_views_rollups

  def recache_grade_distribution
    (cached_grade_distribution || build_cached_grade_distribution).recalculate!
  end

  handle_asynchronously_if_production :recache_grade_distribution,
    :singleton => proc { |c| "recache_grade_distribution:#{ c.global_id }" }
end
