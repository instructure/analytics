require [
  'jquery'
  'i18n!analytics'
  'analytics/compiled/helpers'
  'analytics/compiled/StudentInCourse/CourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseView'
], ($, I18n, helpers, CourseModel, StudentInCourseModel, StudentInCourseView) ->

  # setup initial data from environment
  course = new CourseModel ENV.ANALYTICS.course
  model = new StudentInCourseModel course: course
  model.selectStudent ENV.ANALYTICS.student_id

  # wrap data in view
  view = new StudentInCourseView
    model: model
    startDate: helpers.midnight(Date.parse(ENV.ANALYTICS.startDate), 'floor')
    endDate: helpers.midnight(Date.parse(ENV.ANALYTICS.endDate), 'ceil')

  $('#analytics_body').append view.$el

  toggleTables = ->
    $("#participating-table").toggle()
    $("#responsiveness-table").toggle()
    $("#assignment-finishing-table").toggle()
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