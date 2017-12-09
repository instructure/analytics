#
# Copyright (C) 2016 Instructure, Inc.
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

module Analytics::Extensions
  module CustomSidebarLinksHelper
    def roster_user_custom_links(user)
      links = super
      if analytics_enabled_course? && analytics_enabled_student?(user)
        links << {
          :url => analytics_student_in_course_path(:course_id => @context.id, :student_id => user.id),
          :icon_class => 'icon-analytics',
          :text => I18n.t("Analytics")
        }
      end
      links
    end

    def course_custom_links
      links = super
      if analytics_enabled_course? && @context.grants_right?(@current_user, :read_as_admin)
        links << {
          :url => analytics_course_path(:course_id => @context.id),
          :icon_class => 'icon-analytics',
          :text => I18n.t("View Course Analytics")
        }
      end
      links
    end
  private
    # is the context a course with the necessary conditions to view analytics in
    # the course?
    def analytics_enabled_course?
      RequestCache.cache('analytics_enabled_course', @context) do
        @context.is_a?(Course) &&
        ['available', 'completed'].include?(@context.workflow_state) &&
        service_enabled?(:analytics) &&
        @context.grants_right?(@current_user, session, :view_analytics) &&
        Analytics::Course.available_for?(@current_user, @context)
      end
    end

    # can the user view analytics for this student in the course?
    def analytics_enabled_student?(student)
      analytics = Analytics::StudentInCourse.new(@current_user, @context, student)
      analytics.available? &&
      analytics.enrollment.grants_right?(@current_user, :read_grades)
    end
  end
end
