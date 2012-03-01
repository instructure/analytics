class AnalyticsApiController < ApplicationController
  unloadable

  include AnalyticsPermissions

  before_filter :require_analytics_for_user_in_course

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
end
