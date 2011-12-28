class AnalyticsApiController < ApplicationController
  unloadable

  before_filter :setup_analytics

  def user_participation
    render :json => @analytics.user_participation(api_find(User, params[:user_id]),
        api_find_all(Course, params[:course_ids] || []))
  end

  def course_participation
    render :json => @analytics.course_participation(api_find(Course, params[:course_id]),
        api_find_all(User, params[:user_ids] || []), api_find_all(CourseSection, params[:section_ids] || []))
  end

  def course_assignments
    render :json => @analytics.assignments(api_find(Course, params[:course_id]), api_find_all(User, params[:user_ids] || []))
  end

  def course_user_assignments
    render :json => @analytics.assignments(api_find(Course, params[:course_id]), [api_find(User, params[:user_id])])
  end

  def final_scores
    render :json => @analytics.courses_final_scores(api_find_all(Course, params[:course_ids] || []), :include_totals => true)
  end

  def course_final_scores
    render :json => @analytics.courses_final_scores([api_find(Course, params[:course_id])], :include_individuals => true)
  end

  def course_user_final_scores
    enrollment = api_find(Course, params[:course_id]).student_enrollments.find_by_user_id(api_find(User, params[:user_id]).id)
    raise ActiveRecord::RecordNotFound unless enrollment
    render :json => {:final_score => enrollment.computed_final_score }
  end

private

  def setup_analytics
    @analytics = Analytics.new @current_user
  end

end
