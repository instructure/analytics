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

# while the rows will only ever be queried with respect courses that are
# available or completed course, we don't know at the time of rollup what the
# future workflow state of course will be. so we have to keep rollup data for
# all courses.
class PageViewsRollup < ActiveRecord::Base
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

  def self.bin_scope_for(course)
    if course.instance_of?(Course)
      course.page_views_rollups
    else
      course_id, shard = Shard.local_id_for(course)
      shard ||= Shard.current
      shard.activate { self.where(:course_id => course_id) }
    end
  end

  def self.bin_for(scope, date, category)
    category = category.to_s

    # ensure just the date portion, and that relative to UTC
    if date.is_a?(ActiveSupport::TimeWithZone)
      date = date.in_time_zone('UTC').to_date
    end

    # they passed a course
    unless scope.is_a?(ActiveRecord::Relation)
      scope = bin_scope_for(scope)
    end

    bin = scope.
      for_dates(date).
      for_category(category).
      lock(:no_key_update).
      first

    unless bin
      bin = scope.new
      bin.date = date
      bin.category = category
      bin.views = 0
      bin.participations = 0
    end

    bin
  end

  def self.augment!(course, date, category, views, participations)
    scope = bin_scope_for(course)
    scope.transaction do
      bin = bin_for(scope, date, category)
      bin.augment(views, participations)
      if bin.new_record?
        begin
          bin.transaction(requires_new: true) do
            bin.save!
            return
          end
        rescue ActiveRecord::RecordNotUnique
          bin = bin_for(scope, date, category)
          raise if bin.new_record?
          bin.augment(views, participations)
        end
      end
      bin.save!
    end
  end

  def self.increment!(course, date, category, participated)
    if Setting.get("page_view_rollups_method", "") == "redis" &&
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
      to_increment = [data_key_from_date_and_category(date, category)]
      if participated
        to_increment << data_key_from_date_and_category(date, category, true)
      end
      lua_run(:increment, [key, *to_increment])
      res = true
    rescue => e
      # If this fails for any reason we'll write the values directly
      res = false
    end

    if !res
      increment_db!(course, date, category, participated)
    end
  end

  def self.process_cached_rollups
    lock_key = "page_view_rollup_processing:#{Shard.current.id}"
    lock_time = Setting.get("page_view_rollup_lock_time", 15.minutes.to_s).to_i

    # Lock out other processors, letting the lock drop if we take too long to finish.
    # Move the active set of keys to another set to work on (since new keys
    # will be added to the original set, and we don't necessarily want to
    # worry about them right now.)
    # If that second set already exists, we can assume that a processor failed
    # and we want to finish its work instead of copying the set.
    in_progress_set_key = "#{page_views_rollup_keys_set_key}:in_progress"
    keys = nil
    begin
      # we grab all the keys up front, because redis lua scripts aren't allowed
      # to call the SPOP command (it's non-deterministic).
      keys = lua_run(:process_setup, [in_progress_set_key, lock_key, lock_time])
    rescue => e
      # An error here likely means that the original key does not exist,
      # so there is no work to do.
      return
    end

    begin
      keys&.each do |data_key|
        data = lua_run(:process, [in_progress_set_key, data_key, lock_key, lock_time])
        next if data.nil?

        # different versions of the redis gem return a hash vs an array
        unless data.is_a?(Hash)
          data = Hash[*data]
        end
        course = course_id_from_page_views_rollup_key(data_key)
        data.keys.each do |dk|
          date, category = date_and_category_from_data_key(dk)
          # A nil date means this is a participation, which we'll handle
          # (or handled) as part of the views update.
          next unless date

          views = data[dk]&.to_i || 0
          participations = data["#{dk}:participation"]&.to_i || 0

          augment!(course, date, category, views, participations)
        end
      end

    ensure
      lua_run(:unlock, [lock_key])
    end
  end

  private

  def self.page_views_rollup_keys_set_key
    "page_views_rollup_keys:#{Shard.current.id}"
  end

  # Our use of Redis in this class is a little unusual. When operating on a
  # distributed ring of redis nodes, we want all the data to live on one node,
  # and all the operations to happen against that node. This makes our locking
  # and processing logic a lot simpler, because we can do things like renamenx
  # on the set.
  #
  # Because of this, all the lua calls pass in the same single key, so they'll
  # all run against the node for that key, even as they're acting on other keys
  # hidden inside the args passed to the script.
  #
  # So don't go hitting redis directly for any of this, always go through lua_run.
  def self.lua_run(script_name, args)
    @lua ||= ::Redis::Scripting::Module.new(nil, File.join(File.dirname(__FILE__), "../lua/page_views_rollup"))
    @lua.run(script_name, [page_views_rollup_keys_set_key], args, Canvas.redis)
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
