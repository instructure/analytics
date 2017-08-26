#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Analytics::PageViewIndex
  def analytics_index_backing
    if PageView.pv4?
      PageView.pv4_client
    elsif PageView.cassandra?
      Analytics::PageViewIndex::EventStream
    else
      Analytics::PageViewIndex::DB
    end
  end

  def participations_for_context(context, user)
    analytics_index_backing.participations_for_context(context, user)
  end

  def counters_by_context_and_hour(context, user)
    analytics_index_backing.counters_by_context_and_hour(context, user)
  end

  # Takes a context (right now, only a Course is valid), and a list of User
  # ids. Returns a hash of { user_id => { :page_views => count, :participations => count } }
  def counters_by_context_for_users(context, user_ids)
    analytics_index_backing.counters_by_context_for_users(context, user_ids)
  end

  module EventStream
    def self.database
      PageView::EventStream.database
    end

    def self.bucket_size
      1.hour
    end

    def self.bucket_for_time(time)
      time.to_i - (time.to_i % bucket_size.to_i)
    end

    def self.update(page_view, new_record)
      context = case page_view.context_type
                when 'Course'
                  page_view.context
                when 'Group'
                  if page_view.context.context_type == 'Course'
                    page_view.context.context
                  end
                end
      return unless page_view.user && context

      user = page_view.user
      participation = (new_record || page_view.participated_changed? || page_view.asset_user_access_id_changed?) &&
        page_view.participated &&
        page_view.asset_user_access

      counts_updates = []
      counts_updates << "page_view_count = page_view_count + 1" if new_record
      counts_updates << "participation_count = participation_count + 1" if participation

      unless counts_updates.empty?
        counts_update = counts_updates.join(', ')
        bucket = bucket_for_time(page_view.created_at)
        database.update_counter("UPDATE page_views_counters_by_context_and_hour SET #{counts_update} WHERE context = ? AND hour_bucket = ?", "#{context.global_asset_string}/#{user.global_asset_string}", bucket)
        database.update_counter("UPDATE page_views_counters_by_context_and_user SET #{counts_update} WHERE context = ? AND user_id = ?", context.global_asset_string, user.global_id.to_s)
      end

      if participation
        database.update("INSERT INTO participations_by_context (context, created_at, request_id, url, asset_user_access_id, asset_code, asset_category) VALUES (?, ?, ?, ?, ?, ?, ?)",
                         "#{context.global_asset_string}/#{user.global_asset_string}",
                         page_view.created_at, page_view.request_id,
                         page_view.url, page_view.asset_user_access_id.to_s,
                         page_view.asset_user_access.asset_code,
                         page_view.asset_user_access.asset_category)
      end
    end

    def self.read_consistency_level
      PageView::EventStream.read_consistency_level
    end

    def self.participations_for_context(context, user)
      participations = []
      database.execute("SELECT created_at, url FROM participations_by_context %CONSISTENCY% WHERE context = ?", "#{context.global_asset_string}/#{user.global_asset_string}", consistency: read_consistency_level).fetch do |row|
        participations << row.to_hash.with_indifferent_access
      end
      participations
    end

    def self.counters_by_context_and_hour(context, user)
      counts = ::ActiveSupport::OrderedHash.new
      database.execute("SELECT hour_bucket, page_view_count FROM page_views_counters_by_context_and_hour %CONSISTENCY% WHERE context = ?", "#{context.global_asset_string}/#{user.global_asset_string}", consistency: read_consistency_level).fetch do |row|
        time = row['hour_bucket'].to_i
        if time > 0
          counts[Time.at(time)] = row['page_view_count'] || 0
        end
      end
      counts
    end

    def self.counters_by_context_for_users(context, user_ids)
      counters = {}
      user_ids.each do |id|
        counters[id] = {
          :page_views => 0,
          :participations => 0
        }
      end

      id_map = user_ids.index_by{ |id| Shard.global_id_for(id).to_s }
      database.execute("SELECT user_id, page_view_count, participation_count FROM page_views_counters_by_context_and_user %CONSISTENCY% WHERE context = ?", context.global_asset_string, consistency: read_consistency_level).fetch do |row|
        if id = id_map[row['user_id']]
          counters[id] = {
            :page_views => row['page_view_count'].to_i,
            :participations => row['participation_count'].to_i
          }
        end
      end

      counters
    end
  end

  module DB
    def self.scope_for_context_and_user(context, user)
      contexts = [context] + user.group_memberships_for(context).to_a
      PageView.for_users([user]).polymorphic_where(:context => contexts)
    end

    def self.participations_for_context(context, user)
      scope_for_context_and_user(context, user).
        select("created_at, url").
        where("participated AND asset_user_access_id IS NOT NULL").map do |participation|
          {
            :created_at => participation.created_at,
            :url => participation.url,
          }.with_indifferent_access
      end
    end

    def self.counters_by_context_and_hour(context, user)
      scope_for_context_and_user(context, user).
        group("DATE(created_at)").
        count(:all)
    end

    # Takes a context (right now, only a Course is valid), and a list of User
    # ids. Returns a hash of { user_id => { :page_views => count, :participations => count } }
    def self.counters_by_context_for_users(context, user_ids)
      counters = {}
      user_ids.each do |id|
        counters[id] = {
          :page_views => 0,
          :participations => 0
        }
      end

      # map ids relative to current shard (user_ids) to ids relative to the
      # context's shard (id_map.keys). do the lookups on the context's shard,
      # and map the ids back to those relative to the current shard when
      # populating counters
      id_map = user_ids.index_by{ |id| Shard.relative_id_for(id, Shard.current, context.shard) }

      context.shard.activate do
        contexts = [context] + context.groups.to_a
        PageView.for_users(id_map.keys).polymorphic_where(:context => contexts).group(:user_id).count.each do |relative_user_id,count|
          if id = id_map[relative_user_id]
            counters[id][:page_views] = count
          end
        end

        AssetUserAccess.participations.polymorphic_where(:context => contexts).for_user(id_map.keys).group(:user_id).count.each do |relative_user_id, count|
          if id = id_map[relative_user_id]
            counters[id][:participations] = count
          end
        end
      end

      counters
    end
  end
end
