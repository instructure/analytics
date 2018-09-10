import $ from 'jquery'
import helpers from '../helpers'
import CourseModel from '../Course/CourseModel'
import CourseView from '../Course/CourseView'

// setup initial data from environment
const model = new CourseModel(ENV.ANALYTICS.course)

// wrap data in view
const view = new CourseView({
  model,
  startDate: helpers.midnight(Date.parse(ENV.ANALYTICS.startDate)),
  endDate: helpers.midnight(Date.parse(ENV.ANALYTICS.endDate))
})

$('#analytics_body').append(view.$el)

const toggleTables = function() {
  $('#activities-table').toggle()
  $('#submissions-table').toggle()
  $('#grades-table').toggle()
}

const toggleGraphs = function() {
  $('.graph_legend').toggle()
  $('.graph_container').toggle()
}

$('#graph_table_toggle').on('change', event => {
  toggleTables()
  toggleGraphs()
})
