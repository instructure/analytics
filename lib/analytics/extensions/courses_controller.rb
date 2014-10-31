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

CoursesController.class_eval do
  def show_with_analytics
    # this is a really gross coupling with the implementation of vanilla
    # Course#show, but it seems the best way for now to detect that it
    # unequivocally is rendering the html page (vs. a json response, a
    # redirect, or an "unauthorized")
    show_without_analytics
    return unless @course_home_view

    if analytics_enabled?
      # inject a button to the analytics page for the course
      js_env :ANALYTICS => { 'link' => analytics_course_path(:course_id => @context.id) }
      js_bundle :inject_course_analytics, :plugin => :analytics
      jammit_css :analytics_buttons, :plugin => :analytics
    end

    # continue rendering the page
    render :action => 'show'
  end
  alias_method_chain :show, :analytics

  # we can't be guaranteed our extension to Api::V1::User (if we put it there)
  # would be loaded before Courses is loaded and includes the old version of
  # user_json. so we'll just extend CourseController's copy.
  def user_json_with_analytics(user, current_user, session, includes = [], context = @context, enrollments = nil)
    user_json_without_analytics(user, current_user, session, includes, context, enrollments).tap do |json|
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
  alias_method_chain :user_json, :analytics

  # extend the users API endpoint to request the analytics_url in the user_json
  def users_with_analytics
    # "", [], or nil => []. if it's not one of those, it
    # should already be a non-empty array
    params[:include] = [] if params[:include].blank?
    params[:include] << 'analytics_url'
    users_without_analytics
  end
  alias_method_chain :users, :analytics

  private
  # is the context a course with the necessary conditions to view analytics in
  # the course?
  def analytics_enabled?
    ['available', 'completed'].include?(@context.workflow_state) &&
    service_enabled?(:analytics) &&
    @context.grants_all_rights?(@current_user, session, :view_analytics, :read_as_admin) &&
    Analytics::Course.available_for?(@current_user, @context)
  end
end
