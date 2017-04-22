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

module Analytics::Extensions::CoursesController
  # If Api::V1::User were already included onto User, we're already higher priority
  # than it. Or, by including it, we force it to already be on the chain, so a
  # subsequent inclusion won't make it higher priority than us
  include Api::V1::User

  def user_json(user, current_user, session, includes = [], context = @context, enrollments = nil, excludes=[])
    super.tap do |json|
      # order of comparisons is meant to let the cheapest counters be
      # evalutated first, so the more expensive ones don't need to be evaluated
      # if a cheap one fails
      if includes.include?('analytics_url') && service_enabled?(:analytics)
        enrollment = (enrollments || []).detect do |e|
          ['active', 'completed'].include?(e.workflow_state) &&
          ['StudentEnrollment'].include?(e.type) &&
          ['available', 'completed'].include?(context.workflow_state) &&
          context.grants_right?(current_user, session, :view_analytics) &&
          e.grants_right?(current_user, session, :read_grades)
        end
        if enrollment
          # add the analytics url
          json[:analytics_url] = analytics_student_in_course_path :course_id => enrollment.course_id, :student_id => enrollment.user_id
        end
      end
    end
  end

  # extend the users API endpoint to request the analytics_url in the user_json
  def users
    # "", [], or nil => []. if it's not one of those, it
    # should already be a non-empty array
    params[:include] = [] if params[:include].blank?
    params[:include] << 'analytics_url' unless params[:include].include? 'analytics_url'
    super
  end
end
