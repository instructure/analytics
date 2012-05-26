ActionController::Routing::Routes.draw do |map|
  map.analytics_department 'analytics/accounts/:account_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department'
  map.analytics_department_term 'analytics/accounts/:account_id/terms/:term_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department'
  map.analytics_department_current 'analytics/accounts/:account_id/current', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department', :filter => 'current'
  map.analytics_department_completed 'analytics/accounts/:account_id/completed', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department', :filter => 'completed'

  map.analytics_course 'analytics/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'course'
  map.analytics_student_in_course 'analytics/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'student_in_course'

  ApiRouteSet::V1.route(map) do |api|
    api.with_options(:controller => :analytics_api) do |analytics|
      analytics.get 'analytics/participation/accounts/:account_id/terms/:term_id', :action => :department_participation
      analytics.get 'analytics/participation/accounts/:account_id/current', :action => :department_participation, :filter => 'current'
      analytics.get 'analytics/participation/accounts/:account_id/completed', :action => :department_participation, :filter => 'completed'

      analytics.get 'analytics/grades/accounts/:account_id/terms/:term_id', :action => :department_grades
      analytics.get 'analytics/grades/accounts/:account_id/current', :action => :department_grades, :filter => 'current'
      analytics.get 'analytics/grades/accounts/:account_id/completed', :action => :department_grades, :filter => 'completed'

      analytics.get 'analytics/statistics/accounts/:account_id/terms/:term_id', :action => :department_statistics
      analytics.get 'analytics/statistics/accounts/:account_id/current', :action => :department_statistics, :filter => 'current'
      analytics.get 'analytics/statistics/accounts/:account_id/completed', :action => :department_statistics, :filter => 'completed'

      analytics.get 'analytics/participation/courses/:course_id', :action => :course_participation
      analytics.get 'analytics/assignments/courses/:course_id', :action => :course_assignments
      analytics.get 'analytics/student_summaries/courses/:course_id', :action => :course_student_summaries

      analytics.get 'analytics/participation/courses/:course_id/users/:student_id', :action => :student_in_course_participation
      analytics.get 'analytics/assignments/courses/:course_id/users/:student_id', :action => :student_in_course_assignments
      analytics.get 'analytics/messaging/courses/:course_id/users/:student_id', :action => :student_in_course_messaging
    end
  end
end
