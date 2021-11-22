# frozen_string_literal: true

class AddParticipationsCountToCassandra < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    "page_views"
  end

  def self.up
    cassandra.execute <<~SQL.squish
      ALTER TABLE page_views_counters_by_context_and_user ADD participation_count counter;
    SQL
    cassandra.execute <<~SQL.squish
      ALTER TABLE page_views_counters_by_context_and_hour ADD participation_count counter;
    SQL
  end

  def self.down
    cassandra.execute <<~SQL.squish
      ALTER TABLE page_views_counters_by_context_and_user DROP participation_count;
    SQL
    cassandra.execute <<~SQL.squish
      ALTER TABLE page_views_counters_by_context_and_hour DROP participation_count;
    SQL
  end
end
