import $ from 'jquery'
import DepartmentModel from '../Department/DepartmentModel'
import DepartmentView from '../Department/DepartmentView'

// package up the environment and then use it to build the view
new DepartmentView({
  model: new DepartmentModel(ENV.ANALYTICS),
  el: $('#analytics_body')
})

const toggleTables = function() {
  $('#participating-date-table').toggle()
  $('#participating-category-table').toggle()
  $('#grade-distribution-table').toggle()
}

const toggleGraphs = function() {
  $('.graph_legend').toggle()
  $('.graph_container').toggle()
}

$('#graph_table_toggle').on('change', event => {
  toggleTables()
  toggleGraphs()
})
