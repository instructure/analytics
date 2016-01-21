require [
  'jquery'
  'i18n!analytics'
  'analytics/compiled/helpers'
  'analytics/compiled/Course/CourseModel'
  'analytics/compiled/Course/CourseView'
], ($, i18n, helpers, CourseModel, CourseView) ->

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
    $(".graph").toggle()

  updateToggle = ->
    $toggle = $("#graph_table_toggle")
    if $toggle.is(':checked')
      $toggle.attr('aria-label', I18n.t('Switch to graph view'))
    else
      $toggle.attr('aria-label', I18n.t('Switch to table view'))


  $("#graph_table_toggle").on('change', (event) ->
    updateToggle()
    toggleTables()
    toggleGraphs()
  )