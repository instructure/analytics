# while the rows will only ever be queried with respect courses that are
# available or completed course, we don't know at the time of rollup what the
# future workflow state of course will be. so we have to keep rollup data for
# all courses.
class PageViewsRollup < ActiveRecord::Base
  attr_accessible

  belongs_to :course

  def self.for_dates(date_range)
    where(:date => date_range)
  end

  def self.for_category(category)
    where(:category => category)
  end

  def augment(views, participations)
    self.views += views
    self.participations += participations
  end

  def self.bin_for(course, date, category)
    category = category.to_s

    if course.instance_of?(Course)
      scope = course.page_views_rollups
    else
      course_id, shard = Shard.local_id_for(course)
      shard ||= Shard.current
      scope = self.shard(shard).where(:course_id => course_id)
    end

    bin = scope.
      for_dates(date).
      for_category(category).
      first

    unless bin
      if course.instance_of?(Course)
        bin = scope.build
      else
        bin = self.new
        bin.shard = shard
        bin.course_id = course
      end
      bin.date = date
      bin.category = category
      bin.views = 0
      bin.participations = 0
    end

    bin
  end

  def self.augment!(course, date, category, views, participations)
    bin = bin_for(course, date, category)
    bin.augment(views, participations)
    bin.save
  end

  def self.increment!(course, date, category, participated)
    if Setting.get_cached("page_view_rollups_method", "") == "redis" &&
        Canvas.redis_enabled?
      increment_cached!(course, date, category, participated)
    else
      increment_db!(course, date, category, participated)
    end
  end

  def self.increment_db!(course, date, category, participated)
    augment!(course, date, category, 1, participated ? 1 : 0)
  end

  def self.increment_cached!(course, date, category, participated)
    course_id = course.is_a?(Course) ? course.id : course
    key = page_views_rollup_key_from_course_id(course_id)
    begin
      redis = Canvas.redis
      res = redis.multi do
        redis.hincrby(key, data_key_from_date_and_category(date, category), 1)
        if participated
          redis.hincrby(key, data_key_from_date_and_category(date, category, true), 1)
        end
        redis.sadd(page_views_rollup_keys_set_key, key)
      end
    rescue => e
      # If this fails for any reason we'll write the values directly
      res = nil
    end

    if !res
      increment_db!(course, date, category, participated)
    end
  end

  def self.process_cached_rollups
    redis = Canvas.redis
    lock_key = "page_view_rollup_processing:#{Shard.current.id}"
    lock_time = Setting.get("page_view_rollup_lock_time", 15.minutes.to_s).to_i

    # Lock out other processors, letting the lock drop if we take too long to
    # finish.
    unless redis.setnx lock_key, 1
      return
    end
    redis.expire lock_key, lock_time

    begin
      # Move the active set of keys to another set to work on (since new keys
      # will be added to the original set, and we don't necessarily want to
      # worry about them right now.)
      # If that second set already exists, we can assume that a processor failed
      # and we want to finish its work instead of copying the set.
      in_progress_set_key = "#{page_views_rollup_keys_set_key}:in_progress"
      begin
        redis.renamenx page_views_rollup_keys_set_key, in_progress_set_key
      rescue => e
        # An error here likely means that the original key does not exist,
        # so there is no work to do.
        return
      end

      key = redis.spop in_progress_set_key
      while key
        res = redis.multi do
          redis.hgetall key
          redis.del key

          # Go ahead and grab the next one while we're hitting redis.
          redis.spop in_progress_set_key

          # Refresh our lock every time. This is a O(1) op, and we're hitting
          # redis with a pipeline of commands anyway.
          redis.expire lock_key, lock_time
        end

        course = course_id_from_page_views_rollup_key(key)

        # redis 3.x gem returns a hash, redis 2.x gem returns an array of keys/values
        data = res[0].is_a?(Hash) ? res[0] : Hash[*res[0]]
        data.keys.each do |dk|
          date, category = date_and_category_from_data_key(dk)
          # A nil date means this is a participation, which we'll handle
          # (or handled) as part of the views update.
          next unless date

          views = data[dk].try(:to_i) || 0
          participations = data["#{dk}:participation"].try(:to_i) || 0

          augment!(course, date, category, views, participations)
        end

        key = res[2]
      end

    ensure
      redis.del lock_key
    end
  end

  private

  def self.page_views_rollup_keys_set_key
    "page_views_rollup_keys:#{Shard.current.id}"
  end

  def self.page_views_rollup_key_from_course_id(course)
    [ "page_views_rollup",
      Shard.current.id,
      course.to_s
    ].join ":"
  end

  def self.course_id_from_page_views_rollup_key(key)
    key.split(':')[2].to_i
  end

  def self.data_key_from_date_and_category(date, category, participation = false)
    components = [
      category,
      (Date === date ? date.in_time_zone('UTC') : date.utc.at_beginning_of_day).to_i.to_s
    ]
    components << "participation" if participation
    components.join ":"
  end

  def self.date_and_category_from_data_key(key)
    category, date, participation = key.split(':')
    # participation keys are skipped, so don't bother doing the (fairly)
    # expensive timezone calculations on it.
    return [ nil, nil ] if participation
    [ Time.zone.at(date.to_i), category ]
  end
end
