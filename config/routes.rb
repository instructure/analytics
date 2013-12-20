(CANVAS_RAILS2 ? FakeRails3Routes : CanvasRails::Application.routes).draw do
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
    match department_path, to: :department, as: :department
    # department: specific term
    match department_term_path, to: :department, as: :department_term
    # department: default term, current courses
    match department_current_path, to: :department, :filter => 'current', as: :department_current
    # department: default term, concluded courses
    match department_completed_path, to: :department, :filter => 'completed', as: :department_completed
    # course
    match course_path, to: :course, as: :course
    # student in course
    match student_in_course_path, to: :student_in_course, as: :student_in_course
  end

  ApiRouteSet::V1.draw(self) do
    scope controller: :analytics_api do
      get department_term_path + '/statistics', :to => :department_statistics
      get department_term_path + '/activity', :to => :department_participation
      get department_term_path + '/grades', :to => :department_grades

      get department_current_path + '/statistics', :to => :department_statistics, :filter => 'current'
      get department_current_path + '/activity', :to => :department_participation, :filter => 'current'
      get department_current_path + '/grades', :to => :department_grades, :filter => 'current'

      get department_completed_path + '/statistics', :to => :department_statistics, :filter => 'completed'
      get department_completed_path + '/activity', :to => :department_participation, :filter => 'completed'
      get department_completed_path + '/grades', :to => :department_grades, :filter => 'completed'

      get course_path + '/activity', :to => :course_participation
      get course_path + '/assignments', :to => :course_assignments
      get course_path + '/student_summaries', :to => :course_student_summaries, :path_name => 'course_student_summaries'

      get student_in_course_path + '/activity', :to => :student_in_course_participation
      get student_in_course_path + '/assignments', :to => :student_in_course_assignments
      get student_in_course_path + '/communication', :to => :student_in_course_messaging
    end
  end
end
