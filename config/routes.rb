CanvasRails::Application.routes.draw do
  # common path strings
  department_path = 'accounts/:account_id/analytics'
  department_term_path = department_path + '/terms/:term_id'
  department_current_path = department_path + '/current'
  department_completed_path = department_path + '/completed'
  course_path = 'courses/:course_id/analytics'
  student_in_course_path = course_path + '/users/:student_id'

  scope controller: :analytics, as: 'analytics', via: :get do
    # default department route. basically an alias for one of
    #  - analytics_department_term :term_id => account.default_enrollment_term_id
    #  - analytics_department_current
    # depending on the number of terms in the account
    get department_path, action: :department, as: :department
    # department: specific term
    get department_term_path, action: :department, as: :department_term
    # department: default term, current courses
    get department_current_path, action: :department, :filter => 'current', as: :department_current
    # department: default term, concluded courses
    get department_completed_path, action: :department, :filter => 'completed', as: :department_completed
    # course
    get course_path, action: :course, as: :course
    # student in course
    get student_in_course_path, action: :student_in_course, as: :student_in_course
  end

  ApiRouteSet::V1.draw(self) do
    scope controller: :analytics_api do
      get department_term_path + '/statistics', :action => :department_statistics
      get department_term_path + '/statistics_by_subaccount', :action => :department_statistics_by_subaccount
      get department_term_path + '/activity', :action => :department_participation
      get department_term_path + '/grades', :action => :department_grades

      get department_current_path + '/statistics', :action => :department_statistics, :filter => 'current'
      get department_current_path + '/statistics_by_subaccount', :action => :department_statistics_by_subaccount, :filter => 'current'
      get department_current_path + '/activity', :action => :department_participation, :filter => 'current'
      get department_current_path + '/grades', :action => :department_grades, :filter => 'current'

      get department_completed_path + '/statistics', :action => :department_statistics, :filter => 'completed'
      get department_completed_path + '/statistics_by_subaccount', :action => :department_statistics_by_subaccount, :filter => 'completed'
      get department_completed_path + '/activity', :action => :department_participation, :filter => 'completed'
      get department_completed_path + '/grades', :action => :department_grades, :filter => 'completed'

      get course_path + '/activity', :action => :course_participation
      get course_path + '/assignments', :action => :course_assignments
      get course_path + '/student_summaries', :action => :course_student_summaries, :path_name => 'course_student_summaries'

      get student_in_course_path + '/activity', :action => :student_in_course_participation
      get student_in_course_path + '/assignments', :action => :student_in_course_assignments
      get student_in_course_path + '/communication', :action => :student_in_course_messaging
    end
  end
end
