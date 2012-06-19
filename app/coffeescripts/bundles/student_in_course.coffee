require [
  'jquery'
  'Backbone'
  'analytics/compiled/helpers'
  'analytics/compiled/StudentInCourse/CourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseView'
], ($, Backbone, helpers, CourseModel, StudentInCourseModel, StudentInCourseView) ->

  # setup router for ajax-switching between students
  router = new Backbone.Router
    routes:
      ':student': 'studentInCourse'

  Backbone.history.start
    root: "/courses/#{ENV.ANALYTICS.course.id}/analytics/users/"
    pushState: true

  # setup initial data from environment
  course = new CourseModel ENV.ANALYTICS.course
  students = course.get 'students'
  student = students.get ENV.ANALYTICS.student_id
  model = new StudentInCourseModel {course, student}

  # link data and router
  router.on 'route:studentInCourse', (id) =>
    if student = students.get id
      # switch to that student
      model.set student: student
    else
      # force the server to load the 404 (or 401, or whatever)
      window.location.reload()

  model.on 'change:student', ->
    course = model.get('course')
    student = model.get('student')
    $('title').text "Analytics: #{course.get 'course_code'} -- #{student.get 'short_name'}"
    $('#student_analytics_crumb span').text student.get 'short_name'
    $('#student_analytics_crumb a').attr href: student.get 'analytics_url'
    router.navigate "#{student.get 'id'}#{window.location.search}"

  # wrap data in view
  view = new StudentInCourseView
    model: model
    startDate: helpers.midnight(Date.parse(ENV.ANALYTICS.startDate), 'floor')
    endDate: helpers.midnight(Date.parse(ENV.ANALYTICS.endDate), 'ceil')

  $('#analytics_body').append view.$el
