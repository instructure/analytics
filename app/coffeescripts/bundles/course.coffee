require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/compiled/helpers'
  'analytics/compiled/router'
  'analytics/compiled/Course/CourseModel'
  'analytics/compiled/Course/CourseView'
], ($, helpers, router, CourseModel, CourseView) ->

  # setup initial data from environment
  model = new CourseModel
    course: ENV.ANALYTICS.course
    courses: [ENV.ANALYTICS.course]

  # link data and router
  router.on 'route:course', (courseId) =>
    model.loadById parseInt(courseId, 10)

  model.on 'change:course', ->
    router.navigate "courses/#{model.get('course').id}"

  # wrap data in view
  view = new CourseView
    model: model
    startDate: helpers.midnight Date.parse ENV.ANALYTICS.startDate
    endDate: helpers.midnight Date.parse ENV.ANALYTICS.endDate

  $("#analytics_body").append view.$el
