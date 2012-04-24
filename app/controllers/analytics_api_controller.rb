class AnalyticsApiController < ApplicationController
  unloadable

  include AnalyticsPermissions

  before_filter :require_analytics_for_student_in_course

  def student_in_course_participation
    render :json => {
      :page_views => @student_analytics.page_views,
      :participations => @student_analytics.participations
    }
  end

  def student_in_course_assignments
    render :json => @student_analytics.assignments
  end

  def student_in_course_messaging
    render :json => @student_analytics.messages
  end
end
