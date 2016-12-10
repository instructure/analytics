class AddParticipationsCountToCassandra < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    cassandra.execute %{
      ALTER TABLE page_views_counters_by_context_and_user ADD participation_count counter;
    }
    cassandra.execute %{
      ALTER TABLE page_views_counters_by_context_and_hour ADD participation_count counter;
    }
  end

  def self.down
    cassandra.execute %{
      ALTER TABLE page_views_counters_by_context_and_user DROP participation_count;
    }
    cassandra.execute %{
      ALTER TABLE page_views_counters_by_context_and_hour DROP participation_count;
    }
  end
end
