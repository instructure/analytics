ActionController::Routing::Routes.draw do |map|
  map.connect 'api/v1/analytics/participation/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'user_in_course_participation', :format => 'json'
  map.connect 'api/v1/analytics/assignments/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'user_in_course_assignments', :format => 'json'
  map.connect 'api/v1/analytics/messaging/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'user_in_course_messaging', :format => 'json'

  map.analytics_user_in_course 'analytics/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'user_in_course'
end
