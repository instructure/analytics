#
# Copyright (C) 2017 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Analytics::Extensions::CourseStudentAnalyticsLoader
  def perform(users)
    course = Course.where(workflow_state: %w[available completed], id: @course_id).first
    if course &&
        course.root_account.service_enabled?(:analytics) &&
        course.grants_all_rights?(@current_user, @session, :read_as_admin, :view_analytics) &&
        course.grants_any_right?(@current_user, @session, :manage_grades, :view_all_grades)
      course_analytics = Analytics::Course.new(@current_user, course)
      page_view_counts = course_analytics.page_views_by_student

      student_summaries = Analytics::StudentSummaries.new(course_analytics, page_view_counts)
      students_by_id = course_analytics.student_scope.
        where(users: {id: users}).
        index_by(&:id)

      users.each do |user|
        if analytics_student = students_by_id[user.id]
          fulfill(user, student_summaries.for(analytics_student))
        else
          fulfill(user, nil)
        end
      end
    else
      users.each { |u| fulfill(u, nil) }
    end
  end
end
