define [
  'jquery'
  'analytics/compiled/helpers'
  'analytics/compiled/StudentInCourse/CourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseModel'
  'analytics/compiled/StudentInCourse/StudentInCourseView'
], ($, helpers, CourseModel, StudentInCourseModel, StudentInCourseView) ->

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
    $(".graph_container").toggle()

  $("#graph_table_toggle").on('change', (event) ->
    toggleTables()
    toggleGraphs()
  )