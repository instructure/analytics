require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/compiled/helpers'
  'analytics/compiled/StudentInCourse/StudentInCourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseView'
], ($, helpers, StudentInCourseModel, StudentInCourseView) ->

  # setup initial data from environment
  model = new StudentInCourseModel
    course: ENV.ANALYTICS.course
    student: ENV.ANALYTICS.user

  # wrap data in view
  view = new StudentInCourseView
    model: model
    startDate: helpers.midnight Date.parse ENV.ANALYTICS.startDate
    endDate: helpers.midnight Date.parse ENV.ANALYTICS.endDate

  $('#analytics_body').append view.$el
