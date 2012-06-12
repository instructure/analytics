Delayed::Periodic.cron 'PageViewsRollup.process_cached_rollups', '* * * * *' do
  Shard.with_each_shard do
    PageViewsRollup.send_later_enqueue_args(:process_cached_rollups,
      :singleton => "PageViewsRollup.process_cached_rollups:#{Shard.current.description}")
  end
end
