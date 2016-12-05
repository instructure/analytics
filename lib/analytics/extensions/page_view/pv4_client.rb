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

module Analytics::Extensions::PageView::Pv4Client
  def participations_for_context(context, user)
    json = user_in_course_participations(context, user)

    json['participations'].map do |p|
      { created_at: Time.zone.parse(p['created_at']),
        url: p['url']
      }
    end
  end

  def counters_by_context_and_hour(context, user)
    json = user_in_course_participations(context, user)

    Hash[json['page_views'].map { |(k, v)| [Time.zone.parse(k), v]}]
  end

  # Takes a context (right now, only a Course is valid), and a list of User
  # ids. Returns a hash of { user_id => { :page_views => count, :participations => count } }
  def counters_by_context_for_users(context, user_ids)
    course_id = "#{context.class.name}_#{context.global_id}"
    response = CanvasHttp.get(@uri.merge("courses/#{course_id}/summary").to_s,
                              "Authorization" => "Bearer #{@access_token}")

    json = JSON.parse(response.body)
    Hash[json['users'].map do |entry|
      user_id = Shard.relative_id_for(entry['user_id'], Shard.default, context.shard)
      next unless user_ids.include?(user_id)
      [user_id,
       { page_views: entry['page_views'], participations: entry['participations'] }]
    end.compact]
  end

  private

  # it's highly likely that someone will call participations_by_context and counters_by_context_and_hour
  # in close proximity--which are powered by the same PV4 API--with the same arguments. so cache it
  def user_in_course_participations(context, user)
    course_id = "#{context.class.name}_#{context.global_id}"
    if @last_user_in_course_participations_args == [course_id, user.global_id] &&
       @last_user_in_course_participations_timestamp > Time.now.utc - 5.seconds
      @last_user_in_course_participations
    else
      response = CanvasHttp.get(@uri.merge("courses/#{course_id}/users/#{user.global_id}/participation").to_s,
                                "Authorization" => "Bearer #{@access_token}")

      @last_user_in_course_participations_timestamp = Time.now.utc
      @last_user_in_course_participations_args = [course_id, user.global_id]
      @last_user_in_course_participations = JSON.parse(response.body)
    end
  end
end
