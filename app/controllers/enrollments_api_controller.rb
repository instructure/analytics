require 'app/controllers/enrollments_api_controller'

class EnrollmentsApiController
  # we can't be guaranteed our extension to Api::V1::User (if we put it there)
  # would be loaded before EnrollmentsApiController is loaded and includes the
  # old version of enrollment_json. so we'll just extend
  # EnrollmentsApiController's copy.
  def enrollment_json_with_analytics(enrollment, user, session, includes = [])
    enrollment_json_without_analytics(enrollment, user, session, includes).tap do |json|
      # order of comparisons is meant to let the cheapest counters be
      # evalutated first, so the more expensive ones don't need to be evaluated
      # if a cheap one fails
      if includes.include?('analytics_url') &&
        service_enabled?(:analytics) &&
        ['active', 'completed'].include?(enrollment.workflow_state) &&
        ['StudentEnrollment'].include?(enrollment.type) &&
        ['available', 'completed'].include?(enrollment.course.workflow_state) &&
        enrollment.course.grants_right?(user, session, :view_analytics) &&
        enrollment.grants_right?(user, session, :read_grades)

        # add the analytics url
        json[:analytics_url] = analytics_student_in_course_path :course_id => enrollment.course_id, :student_id => enrollment.user_id
      end
    end
  end
  alias_method_chain :enrollment_json, :analytics

  # extend the index to request the analytics_url in the enrollment_json
  def index_with_analytics
    # "", [], or nil => []. if it's not one of those, it should already be a
    # non-empty array
    params[:include] = [] if params[:include].blank?
    params[:include] << 'analytics_url'
    index_without_analytics
  end
  alias_method_chain :index, :analytics
end
