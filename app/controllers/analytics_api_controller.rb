class AnalyticsApiController < ApplicationController
  unloadable

  before_filter :require_user
  before_filter :setup_user_in_course_analytics
  before_filter :require_view_statistics
  before_filter :require_course_read

  def user_in_course_participation
    render :json => {
      :page_views => @analytics.page_views,
      :participations => @analytics.participations
    }
  end

  def user_in_course_assignments
    render :json => @analytics.assignments
  end

  def user_in_course_messaging
    render :json => @analytics.messages
  end

private

  def setup_user_in_course_analytics
    if !service_enabled?(:analytics)
      # analytics? what analytics?
      render :json => {}, :status => :not_found
      return false
    end

    @course = api_find(Course, params[:course_id])
    @user = api_find(User, params[:user_id])
    @analytics = Analytics::UserInCourse.new(@current_user, session, @course, @user)
    if @analytics.enrollments.empty?
      # the user is not in the course (that you know of!)
      render :json => {}, :status => :not_found
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
