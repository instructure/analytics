class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Course
  include Api::V1::User
  include AnalyticsPermissions

  before_filter :require_analytics_for_user_in_course

  def user_in_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @user_json = extended_user_json(@user, @analytics.enrollments.first)
    @students = Analytics::UserInCourse.available_enrollments(@current_user, @course).
      map{ |enrollment| extended_user_json(enrollment.user, enrollment) }
    @start_date = @analytics.start_date
    @end_date = @analytics.end_date
  end

  private
  def extended_user_json(user, enrollment)
    json = user_json(user, @current_user, session, ['avatar_url'], @course)
    json[:current_score] = enrollment.computed_current_score
    json[:html_url] = polymorphic_url [@course, user]
    json
  end
end
