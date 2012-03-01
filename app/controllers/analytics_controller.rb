class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Course
  include Api::V1::User
  include AnalyticsPermissions

  before_filter :require_analytics_for_user_in_course

  def user_in_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @user_json = user_json(@user, @current_user, session, ['avatar_url'], @course)
    @user_json[:current_score] = @analytics.enrollments.first.computed_current_score
    @user_json[:html_url] = polymorphic_url [@course, @user]
    @start_date = @analytics.start_date
    @end_date = @analytics.end_date
  end
end
