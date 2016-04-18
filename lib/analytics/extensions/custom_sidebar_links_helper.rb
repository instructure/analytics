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

CustomSidebarLinksHelper.class_eval do
  def roster_user_custom_links_with_analytics(user)
    links = roster_user_custom_links_without_analytics(user)
    if analytics_enabled_course? && analytics_enabled_student?(user)
      links << {
        :url => analytics_student_in_course_path(:course_id => @context.id, :student_id => user.id),
        :icon_class => 'icon-analytics',
        :text => I18n.t("Analytics")
      }
    end
    links
  end
  alias_method_chain :roster_user_custom_links, :analytics

  def course_custom_links_with_analytics
    links = course_custom_links_without_analytics
    if analytics_enabled_course? && @context.grants_right?(@current_user, :read_as_admin)
      links << {
        :url => analytics_course_path(:course_id => @context.id),
        :icon_class => 'icon-analytics',
        :text => I18n.t("View Course Analytics")
      }
    end
    links
  end
  alias_method_chain :course_custom_links, :analytics

  def account_custom_links_with_analytics
    links = account_custom_links_without_analytics
    if analytics_enabled_account?
      links << {
        :url => analytics_department_path(:account_id => @account.id),
        :icon_class => 'icon-analytics',
        :text => I18n.t("View Analytics")
      }
    end
    links
  end
  alias_method_chain :account_custom_links, :analytics

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

  # is analytics enabled in the account, and does the user have permission to see it?
  def analytics_enabled_account?
    @account.active? && service_enabled?(:analytics) &&
    @account.grants_right?(@current_user, session, :view_analytics)
  end
end