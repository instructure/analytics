class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Course
  include Api::V1::User
  include AnalyticsPermissions

  def course
    return unless require_analytics_for_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @course_json[:students] = @course_analytics.enrollments.
      map{ |enrollment| student_json(enrollment.user, enrollment) }
    @start_date = @course_analytics.start_date
    @end_date = @course_analytics.end_date
  end

  def student_in_course
    return unless require_analytics_for_student_in_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @student_json = student_json(@student, @student_analytics.enrollment)
    @students = @course_analytics.enrollments.
      map{ |enrollment| student_json(enrollment.user, enrollment) }
    @start_date = @student_analytics.start_date
    @end_date = @student_analytics.end_date
  end

  private
  def student_json(student, enrollment)
    json = user_json(student, @current_user, session, ['avatar_url'], @course)
    json[:current_score] = enrollment.computed_current_score
    json[:html_url] = polymorphic_url [@course, student]
    json[:analytics_url] = analytics_student_in_course_path(:course_id => @course.id, :student_id => student.id)
    json
  end
end
