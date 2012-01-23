class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Course
  include Api::V1::User

  before_filter :require_user
  before_filter :setup_user_in_course_analytics
  before_filter :require_view_statistics
  before_filter :require_course_read

  def user_in_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @user_json = user_json(@user, @current_user, session, ['avatar_url'], @course)
    @user_json[:current_score] = @analytics.enrollments.first.computed_current_score
    @user_json[:html_url] = polymorphic_url [@course, @user]
    @start_date = @analytics.start_date
    @end_date = @analytics.end_date
  end

private

  def setup_user_in_course_analytics
    if !service_enabled?(:analytics)
      # analytics? what analytics?
      render :template => 'shared/errors/404_message', :status => :not_found
      return false
    end

    @course = api_find(Course, params[:course_id])
    @user = api_find(User, params[:user_id])
    @analytics = Analytics::UserInCourse.new(@current_user, session, @course, @user)
    if @analytics.enrollments.empty?
      # the user is not in the course (that you know of!)
      render :template => 'shared/errors/404_message', :status => :not_found
      return false
    else
      return true
    end
  end

  def require_view_statistics
    @user == @current_user || authorized_action(@user, @current_user, :view_statistics)
  end

  def require_course_read
    authorized_action(@course, @current_user, :read)
  end

end
