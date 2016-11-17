class AddCassandraPageViewAnalyticsTables < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
      "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
      "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE participations_by_context (
        context text,
        created_at timestamp,
        request_id text,
        asset_category text,
        asset_code text,
        asset_user_access_id text,
        url text,
        PRIMARY KEY (context, created_at, request_id)
      ) #{compression_params}}

    cassandra.execute %{
      CREATE TABLE page_views_counters_by_context_and_hour (
        context text,
        hour_bucket int,
        page_view_count counter,
        PRIMARY KEY (context, hour_bucket)
      ) #{compression_params}}

    cassandra.execute %{
      CREATE TABLE page_views_counters_by_context_and_user (
        context text,
        user_id text,
        page_view_count counter,
        PRIMARY KEY (context, user_id)
      ) #{compression_params}}
  end

  def self.down
    cassandra.execute %{
      DROP TABLE participations_by_context;
    }
    cassandra.execute %{
      DROP TABLE page_views_counters_by_context_and_hour;
    }
    cassandra.execute %{
      DROP TABLE page_views_counters_by_context_and_user;
    }
  end
end
