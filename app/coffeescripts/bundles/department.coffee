require [
  'jquery',
  'i18n!analytics'
  'analytics/compiled/Department/DepartmentModel'
  'analytics/compiled/Department/DepartmentView'
], ($, I18n, DepartmentModel, DepartmentView) ->

  # package up the environment and then use it to build the view
  new DepartmentView
    model: new DepartmentModel ENV.ANALYTICS
    el: $('#analytics_body')

  toggleTables = ->
    $("#participating-date-table").toggle()
    $("#participating-category-table").toggle()
    $("#grade-distribution-table").toggle()

  toggleGraphs = ->
    $(".graph_legend").toggle()
    $(".graph_container").toggle()

  $("#graph_table_toggle").on('change', (event) ->
    toggleTables()
    toggleGraphs()
  )