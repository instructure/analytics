ActionController::Routing::Routes.draw do |map|
  map.analytics_course 'analytics/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'course'
  map.analytics_student_in_course 'analytics/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'student_in_course'

  map.connect 'api/v1/analytics/participation/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_participation', :format => 'json'
  map.connect 'api/v1/analytics/assignments/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_assignments', :format => 'json'
  map.connect 'api/v1/analytics/student_summaries/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'course_student_summaries', :format => 'json'

  map.connect 'api/v1/analytics/participation/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'student_in_course_participation', :format => 'json'
  map.connect 'api/v1/analytics/assignments/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'student_in_course_assignments', :format => 'json'
  map.connect 'api/v1/analytics/messaging/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics_api', :action => 'student_in_course_messaging', :format => 'json'
end
