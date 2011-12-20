class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Course
  include Api::V1::User

  before_filter :setup_analytics

  def user_in_course
    @course = api_find(Course, params[:course_id])
    @user = api_find(User, params[:user_id])

    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @user_json = user_json(@user, @current_user, session, ['avatar_url'], @course)
    @start_date = @analytics.start_date([@course], [@user], [])
    @end_date = @analytics.end_date([@course], [@user], [])
  end

private

  def setup_analytics
    @analytics = Analytics.new @current_user
  end

end
