ActionController::Routing::Routes.draw do |map|
  map.with_options(:controller => :analytics, :name_prefix => 'analytics_', :conditions => { :method => :get }) do |analytics|
    ApiRouteSet::V1.route(map) do |api|
      api.with_options(:controller => :analytics_api) do |api|

        # common path strings
        department_path = 'accounts/:account_id/analytics'
        department_term_path = department_path + '/terms/:term_id'
        department_current_path = department_path + '/current'
        department_completed_path = department_path + '/completed'
        course_path = 'courses/:course_id/analytics'
        student_in_course_path = course_path + '/users/:student_id'

        # default department route. basically an alias for one of
        #  - analytics_department_term :term_id => account.default_enrollment_term_id
        #  - analytics_department_current
        # depending on the number of terms in the account
        analytics.department department_path, :action => 'department'

        # department: specific term
        analytics.department_term department_term_path, :action => 'department'
        api.get department_term_path + '/statistics', :action => :department_statistics
        api.get department_term_path + '/activity', :action => :department_participation
        api.get department_term_path + '/grades', :action => :department_grades

        # department: default term, current courses
        analytics.department_current department_current_path, :action => 'department', :filter => 'current'
        api.get department_current_path + '/statistics', :action => :department_statistics, :filter => 'current'
        api.get department_current_path + '/activity', :action => :department_participation, :filter => 'current'
        api.get department_current_path + '/grades', :action => :department_grades, :filter => 'current'

        # department: default term, concluded courses
        analytics.department_completed department_completed_path, :action => 'department', :filter => 'completed'
        api.get department_completed_path + '/statistics', :action => :department_statistics, :filter => 'completed'
        api.get department_completed_path + '/activity', :action => :department_participation, :filter => 'completed'
        api.get department_completed_path + '/grades', :action => :department_grades, :filter => 'completed'

        # course
        analytics.course course_path + '', :action => 'course'
        api.get course_path + '/activity', :action => :course_participation
        api.get course_path + '/assignments', :action => :course_assignments
        api.get course_path + '/student_summaries', :action => :course_student_summaries

        # student in course
        analytics.student_in_course student_in_course_path, :action => 'student_in_course'
        api.get student_in_course_path + '/activity', :action => :student_in_course_participation
        api.get student_in_course_path + '/assignments', :action => :student_in_course_assignments
        api.get student_in_course_path + '/communication', :action => :student_in_course_messaging
      end
    end
  end

  # old deprecated routes. kept for a short while for backwards compatibility
  map.analytics_department_deprecated 'analytics/accounts/:account_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department'
  map.analytics_department_term_deprecated 'analytics/accounts/:account_id/terms/:term_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department'
  map.analytics_department_current_deprecated 'analytics/accounts/:account_id/current', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department', :filter => 'current'
  map.analytics_department_completed_deprecated 'analytics/accounts/:account_id/completed', :conditions => { :method => :get }, :controller => 'analytics', :action => 'department', :filter => 'completed'

  map.analytics_course_deprecated 'analytics/courses/:course_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'course'
  map.analytics_student_in_course_deprecated 'analytics/courses/:course_id/users/:student_id', :conditions => { :method => :get }, :controller => 'analytics', :action => 'student_in_course'

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
