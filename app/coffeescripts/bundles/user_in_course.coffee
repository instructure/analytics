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
    student: ENV.ANALYTICS.user
    students: ENV.ANALYTICS.students

  # link data and router
  router.on 'route:studentInCourse', (courseId, studentId) =>
    model.loadById parseInt(courseId, 10), parseInt(studentId, 10)

  model.on 'change:student', ->
    router.navigate "courses/#{model.get('course').id}/users/#{model.get('student').id}"

  model.on 'change:course', ->
    router.navigate "courses/#{model.get('course').id}/users/#{model.get('student').id}"

  # wrap data in view
  view = new StudentInCourseView
    model: model
    startDate: helpers.midnight Date.parse ENV.ANALYTICS.startDate
    endDate: helpers.midnight Date.parse ENV.ANALYTICS.endDate

  $('#analytics_body').append view.$el
