# frozen_string_literal: true

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
    else
      Analytics::PageViewIndex::DB
    end
  end

  delegate :participations_for_context, to: :analytics_index_backing

  delegate :counters_by_context_and_hour, to: :analytics_index_backing

  # Takes a context (right now, only a Course is valid), and a list of User
  # ids. Returns a hash of { user_id => { :page_views => count, :participations => count } }
  delegate :counters_by_context_for_users, to: :analytics_index_backing

  module DB
    def self.scope_for_context_and_user(context, user)
      contexts = [context] + user.group_memberships_for(context).to_a
      PageView.for_users([user]).where(context: contexts)
    end

    def self.participations_for_context(context, user)
      scope_for_context_and_user(context, user)
        .select("created_at, url")
        .where("participated AND asset_user_access_id IS NOT NULL").map do |participation|
        {
          created_at: participation.created_at,
          url: participation.url,
        }.with_indifferent_access
      end
    end

    def self.counters_by_context_and_hour(context, user)
      scope_for_context_and_user(context, user)
        .group("DATE(created_at)")
        .count(:all)
    end

    # Takes a context (right now, only a Course is valid), and a list of User
    # ids. Returns a hash of { user_id => { :page_views => count, :participations => count } }
    def self.counters_by_context_for_users(context, user_ids)
      counters = {}
      user_ids.each do |id|
        counters[id] = {
          page_views: 0,
          participations: 0
        }
      end

      # map ids relative to current shard (user_ids) to ids relative to the
      # context's shard (id_map.keys). do the lookups on the context's shard,
      # and map the ids back to those relative to the current shard when
      # populating counters
      id_map = user_ids.index_by { |id| Shard.relative_id_for(id, Shard.current, context.shard) }

      context.shard.activate do
        contexts = [context] + context.groups.to_a
        PageView.for_users(id_map.keys).where(context: contexts).group(:user_id).count.each do |relative_user_id, count|
          if (id = id_map[relative_user_id])
            counters[id][:page_views] = count
          end
        end

        AssetUserAccess.participations.where(context: contexts).for_user(id_map.keys).group(:user_id).count.each do |relative_user_id, count|
          if (id = id_map[relative_user_id])
            counters[id][:participations] = count
          end
        end
      end

      counters
    end
  end
end
