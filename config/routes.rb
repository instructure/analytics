ActionController::Routing::Routes.draw do |map|
  map.connect 'api/v1/analytics/participation/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'user_participation', :format => 'json'
  map.connect 'api/v1/analytics/participation/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_participation', :format => 'json'

  map.connect 'api/v1/analytics/assignments/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_assignments', :format => 'json'
  map.connect 'api/v1/analytics/assignments/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_user_assignments', :format => 'json'

  map.connect 'analytics/courses/:course_id/users/:user_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'user_in_course'
end
