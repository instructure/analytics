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

ContextController.class_eval do
  def roster_with_analytics
    return unless roster_without_analytics
    if analytics_enabled_course?
      js_bundle :inject_roster_analytics, :plugin => :analytics
      css_bundle :analytics_buttons, :plugin => :analytics
    end
    render :action => 'roster'
  end
  alias_method_chain :roster, :analytics

  def roster_user_with_analytics
    return unless roster_user_without_analytics

    if analytics_enabled_course? && analytics_enabled_student?(@user)
      # inject a button to the analytics page for the student in the course
      js_env :ANALYTICS => {
        'link' => analytics_student_in_course_path(:course_id => @context.id, :student_id => @user.id),
        'student_name' => @user.short_name || @user.name
      }
      js_bundle :inject_roster_user_analytics, :plugin => :analytics
      css_bundle :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'roster_user'
  end
  alias_method_chain :roster_user, :analytics

  private
  # is the context a course with the necessary conditions to view analytics in
  # the course?
  def analytics_enabled_course?
    @context.is_a?(Course) &&
    ['available', 'completed'].include?(@context.workflow_state) &&
    service_enabled?(:analytics) &&
    @context.grants_right?(@current_user, session, :view_analytics) &&
    Analytics::Course.available_for?(@current_user, @context)
  end

  # can the user view analytics for this student in the course?
  def analytics_enabled_student?(student)
    analytics = Analytics::StudentInCourse.new(@current_user, @context, student)
    analytics.available? &&
    analytics.enrollment.grants_right?(@current_user, :read_grades)
  end
end
