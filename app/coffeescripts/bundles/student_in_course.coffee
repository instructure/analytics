require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/compiled/helpers'
  'analytics/compiled/router'
  'analytics/compiled/StudentInCourse/StudentInCourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseView'
], ($, helpers, router, StudentInCourseModel, StudentInCourseView) ->

  # setup initial data from environment
  model = new StudentInCourseModel
    course: ENV.ANALYTICS.course
    courses: [ENV.ANALYTICS.course]
    student: ENV.ANALYTICS.student
    students: ENV.ANALYTICS.students

  # link data and router
  router.on 'route:studentInCourse', (courseId, studentId) =>
    model.loadById parseInt(courseId, 10), parseInt(studentId, 10)

  model.on 'change:student change:course', ->
    course = model.get('course')
    student = model.get('student')
    $('title').text "Analytics: #{course.short_name} -- #{student.short_name}"
    $('#student_analytics_crumb span').text student.short_name
    $('#student_analytics_crumb a').attr href: student.analytics_url
    router.navigate "courses/#{course.id}/users/#{student.id}"

  # wrap data in view
  view = new StudentInCourseView
    model: model
    startDate: helpers.midnight Date.parse ENV.ANALYTICS.startDate
    endDate: helpers.midnight Date.parse ENV.ANALYTICS.endDate

  $('#analytics_body').append view.$el
