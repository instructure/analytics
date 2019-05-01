define [
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

  toggleTables = ->
    $("#activities-table").toggle()
    $("#submissions-table").toggle()
    $("#grades-table").toggle()

  toggleGraphs = ->
    $(".graph_legend").toggle()
    $(".graph_container").toggle()

  $("#graph_table_toggle").on('change', (event) ->
    toggleTables()
    toggleGraphs()
  )