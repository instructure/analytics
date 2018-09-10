import $ from 'jquery'
import helpers from '../helpers'
import CourseModel from '../StudentInCourse/CourseModel'
import StudentInCourseModel from '../StudentInCourse/StudentInCourseModel'
import StudentInCourseView from '../StudentInCourse/StudentInCourseView'

// setup initial data from environment
const course = new CourseModel(ENV.ANALYTICS.course)
const model = new StudentInCourseModel({course})
model.selectStudent(ENV.ANALYTICS.student_id)

// wrap data in view
const view = new StudentInCourseView({
  model,
  startDate: helpers.midnight(Date.parse(ENV.ANALYTICS.startDate), 'floor'),
  endDate: helpers.midnight(Date.parse(ENV.ANALYTICS.endDate), 'ceil')
})

$('#analytics_body').append(view.$el)

const toggleTables = function() {
  $('#participating-table').toggle()
  $('#responsiveness-table').toggle()
  $('#assignment-finishing-table').toggle()
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
