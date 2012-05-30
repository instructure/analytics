ActionController::Routing::Routes.draw do |map|
  map.analytics_course 'analytics/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'course'
  map.analytics_student_in_course 'analytics/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'student_in_course'

  ApiRouteSet::V1.route(map) do |api|
    api.with_options(:controller => :analytics_api) do |analytics|
      analytics.get 'analytics/participation/courses/:course_id', :action => :course_participation
      analytics.get 'analytics/assignments/courses/:course_id', :action => :course_assignments
      analytics.get 'analytics/student_summaries/courses/:course_id', :action => :course_student_summaries

      analytics.get 'analytics/participation/courses/:course_id/users/:student_id', :action => :student_in_course_participation
      analytics.get 'analytics/assignments/courses/:course_id/users/:student_id', :action => :student_in_course_assignments
      analytics.get 'analytics/messaging/courses/:course_id/users/:student_id', :action => :student_in_course_messaging
    end
  end
end
