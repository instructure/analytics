class AnalyticsApiController < ApplicationController
  unloadable

  include AnalyticsPermissions

  def course_participation
    return unless require_analytics_for_course
    render :json => {
      :page_views => @course_analytics.page_views,
      :participations => @course_analytics.participations
    }
  end

  def course_assignments
    return unless require_analytics_for_course
    render :json => @course_analytics.assignments
  end

  def course_student_summaries
    return unless require_analytics_for_course
    render :json => @course_analytics.student_summaries
  end

  def student_in_course_participation
    return unless require_analytics_for_student_in_course
    render :json => {
      :page_views => @student_analytics.page_views,
      :participations => @student_analytics.participations
    }
  end

  def student_in_course_assignments
    return unless require_analytics_for_student_in_course
    render :json => @student_analytics.assignments
  end

  def student_in_course_messaging
    return unless require_analytics_for_student_in_course
    render :json => @student_analytics.messages
  end
end
