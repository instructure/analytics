PageView.class_eval do
  def category
    category = read_attribute(:category)
    if !category && read_attribute(:controller)
      category = CONTROLLER_TO_ACTION[controller.downcase.to_sym]
    end
    category || :other
  end

  def store_with_rollup
    self.summarized = true
    result = store_without_rollup
    if context_id && context_type == 'Course'
      PageViewsRollup.increment!(context_id, created_at, category, participated && asset_user_access_id)
    end
    result
  end
  alias_method_chain :store, :rollup

  after_create :create_analytics_cassandra
  def create_analytics_cassandra
    if cassandra?
      hour_bucket = PageView.hour_bucket_for_time(created_at)
      counts_update = "page_view_count = page_view_count + 1"
      if self.participated
        counts_update += ", participation_count = participation_count + 1"
      end
      if user
        cassandra.execute("UPDATE page_views_counters_by_context_and_hour SET #{counts_update} WHERE context = ? AND hour_bucket = ?", user.global_asset_string, hour_bucket)
      end
      if user && context_type == 'Course' && context
        cassandra.execute("UPDATE page_views_counters_by_context_and_hour SET #{counts_update} WHERE context = ? AND hour_bucket = ?", "#{context.global_asset_string}/#{user.global_asset_string}", hour_bucket)
        cassandra.execute("UPDATE page_views_counters_by_context_and_user SET #{counts_update} WHERE context = ? AND user_id = ?", context.global_asset_string, user.global_id)
      end
    end
    true
  end

  after_save :update_analytics_cassandra
  def update_analytics_cassandra
    if cassandra?
      if context_type == 'Course' && context_id && self.participated && self.asset_user_access
        cassandra.execute("INSERT INTO participations_by_context (context, created_at, request_id, url, asset_user_access_id, asset_code, asset_category) VALUES (?, ?, ?, ?, ?, ?, ?)", "#{context.global_asset_string}/#{user.global_asset_string}", created_at, request_id, url, asset_user_access_id, asset_user_access.asset_code, asset_user_access.asset_category)
      end
    end
    true
  end

  def self.hour_bucket_for_time(time)
    time.to_i - (time.to_i % 1.hour)
  end

  def self.participations_for_context(context, user)
    participations = []
    if cassandra?
      cassandra.execute("SELECT created_at, url, asset_code, asset_category FROM participations_by_context WHERE context = ?", "#{context.global_asset_string}/#{user.global_asset_string}").fetch do |row|
        participations << row.to_hash.with_indifferent_access
      end
    else
      self.for_context(context).for_users([user]).all(
        :select => "page_views.created_at, page_views.url, asset_user_accesses.asset_code, asset_user_accesses.asset_category",
        :include => :asset_user_access,
        :conditions => "page_views.participated AND page_views.asset_user_access_id IS NOT NULL").map do |participation|
          participations << {
            :created_at => participation.created_at,
            :url => participation.url,
            :asset_code => participation.asset_user_access.asset_code,
            :asset_category => participation.asset_user_access.asset_category
          }.with_indifferent_access
      end
    end
    participations
  end

  def self.counters_by_context_and_hour(context, user)
    counts = ::ActiveSupport::OrderedHash.new
    if cassandra?
      cassandra.execute("SELECT hour_bucket, page_view_count FROM page_views_counters_by_context_and_hour WHERE context = ?", "#{context.global_asset_string}/user_#{user.global_id}").fetch do |row|
        time = row['hour_bucket'].to_i
        if time > 0
          counts[Time.at(time)] = row['page_view_count'] || 0
        end
      end
    else
      self.for_context(context).for_users([user]).all(
          :select => "DATE(created_at) AS day, COUNT(*) AS ct",
          :group => "DATE(created_at)").each do |row|
        day = row.day
        count = row.ct.to_i
        counts[day] ||= 0
        counts[day] += count
      end
    end
    counts
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

    if cassandra?
      id_map = user_ids.inject({}) { |h,id| h[Shard.global_id_for(id).to_s] = id; h }
      cassandra.execute("SELECT user_id, page_view_count, participation_count FROM page_views_counters_by_context_and_user WHERE context = ?", context.global_asset_string).fetch do |row|
        if id = id_map[row['user_id']]
          counters[id][:page_views] = row['page_view_count'].to_i
          counters[id][:participations] = row['participation_count'].to_i
        end
      end
    else
      # map ids relative to current shard (user_ids) to ids relative to the
      # context's shard (id_map.keys). do the lookups on the context's shard,
      # and map the ids back to those relative to the current shard when
      # populating counters
      id_map = user_ids.inject({}) { |h,id| h[Shard.relative_id_for(id, context.shard)] = id; h }

      context.shard.activate do
        self.for_context(context).for_users(id_map.keys).count(:group => :user_id).each do |relative_user_id,count|
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
    end

    counters
  end

  CONTROLLER_TO_ACTION = {
    :assignments         => :assignments,
    :courses             => :general,
    :quizzes             => :quizzes,
    :wiki_pages          => :pages,
    :gradebooks          => :grades,
    :submissions         => :assignments,
    :discussion_topics   => :discussions,
    :files               => :files,
    :context_modules     => :modules,
    :announcements       => :announcements,
    :collaborations      => :collaborations,
    :conferences         => :conferences,
    :groups              => :groups,
    :question_banks      => :quizzes,
    :gradebook2          => :grades,
    :wiki_page_revisions => :pages,
    :folders             => :files,
    :grading_standards   => :grades,
    :discussion_entries  => :discussions,
    :assignment_groups   => :assignments,
    :quiz_questions      => :quizzes,
    :gradebook_uploads   => :grades
  }
end
