require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/compiled/helpers'
  'analytics/compiled/Course/CourseModel'
  'analytics/compiled/Course/CourseView'
], ($, helpers, CourseModel, CourseView) ->

  # setup initial data from environment
  model = new CourseModel ENV.ANALYTICS.course

  # wrap data in view
  view = new CourseView
    model: model
    startDate: helpers.midnight Date.parse ENV.ANALYTICS.startDate
    endDate: helpers.midnight Date.parse ENV.ANALYTICS.endDate

  $("#analytics_body").append view.$el
