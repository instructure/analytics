module Analytics::PageViewIndex
  def analytics_index_backing
    if PageView.cassandra?
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
      time.to_i - (time.to_i % bucket_size)
    end

    def self.update(page_view, new_record)
      return unless page_view.user && page_view.context_type == 'Course' && page_view.context

      user, context = page_view.user, page_view.context
      participation = (new_record || page_view.participated_changed? || page_view.asset_user_access_id_changed?) &&
        page_view.participated &&
        page_view.asset_user_access

      counts_updates = []
      counts_updates << "page_view_count = page_view_count + 1" if new_record
      counts_updates << "participation_count = participation_count + 1" if participation

      unless counts_updates.empty?
        counts_update = counts_updates.join(', ')
        bucket = bucket_for_time(page_view.created_at)
        database.update("UPDATE page_views_counters_by_context_and_hour SET #{counts_update} WHERE context = ? AND hour_bucket = ?", "#{context.global_asset_string}/#{user.global_asset_string}", bucket)
        database.update("UPDATE page_views_counters_by_context_and_user SET #{counts_update} WHERE context = ? AND user_id = ?", context.global_asset_string, user.global_id)
      end

      if participation
        database.update("INSERT INTO participations_by_context (context, created_at, request_id, url, asset_user_access_id, asset_code, asset_category) VALUES (?, ?, ?, ?, ?, ?, ?)",
                         "#{context.global_asset_string}/#{user.global_asset_string}",
                         page_view.created_at, page_view.request_id,
                         page_view.url, page_view.asset_user_access_id,
                         page_view.asset_user_access.asset_code,
                         page_view.asset_user_access.asset_category)
      end
    end

    def self.participations_for_context(context, user)
      participations = []
      database.execute("SELECT created_at, url, asset_code, asset_category FROM participations_by_context WHERE context = ?", "#{context.global_asset_string}/#{user.global_asset_string}").fetch do |row|
        participations << row.to_hash.with_indifferent_access
      end
      participations
    end

    def self.counters_by_context_and_hour(context, user)
      counts = ::ActiveSupport::OrderedHash.new
      database.execute("SELECT hour_bucket, page_view_count FROM page_views_counters_by_context_and_hour WHERE context = ?", "#{context.global_asset_string}/#{user.global_asset_string}").fetch do |row|
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
      database.execute("SELECT user_id, page_view_count, participation_count FROM page_views_counters_by_context_and_user WHERE context = ?", context.global_asset_string).fetch do |row|
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
    def self.participations_for_context(context, user)
      PageView.for_context(context).for_users([user]).
        select("page_views.created_at, page_views.url, asset_user_accesses.asset_code AS asset_code, asset_user_accesses.asset_category AS asset_category").
        joins(:asset_user_access).
        where("page_views.participated AND page_views.asset_user_access_id IS NOT NULL").map do |participation|
          {
            :created_at => participation.created_at,
            :url => participation.url,
            :asset_code => participation.asset_code,
            :asset_category => participation.asset_category
          }.with_indifferent_access
      end
    end

    def self.counters_by_context_and_hour(context, user)
      PageView.for_context(context).for_users([user]).
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
      id_map = user_ids.index_by{ |id| Shard.relative_id_for(id, context.shard) }

      context.shard.activate do
        PageView.for_context(context).for_users(id_map.keys).count(:group => :user_id).each do |relative_user_id,count|
          if id = id_map[relative_user_id]
            counters[id][:page_views] = count
          end
        end

        context.asset_user_accesses.participations.for_user(id_map.keys).count(:group => :user_id).each do |relative_user_id, count|
          if id = id_map[relative_user_id]
            counters[id][:participations] = count
          end
        end
      end

      counters
    end
  end
end
