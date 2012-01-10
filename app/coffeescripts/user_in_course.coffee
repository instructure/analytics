require.config(
  paths:
    canvalytics: "/plugins/canvalytics/javascripts"
)

require [
  'jquery'
  'canvalytics/jst/user_in_course'
  'ENV'
  'canvalytics/compiled/calls/participation'
  'canvalytics/compiled/calls/assignments'
], ($, template, ENV, participation, assignments) ->

  $("#analytics_body").html(template(
    user: ENV.analytics.user
    course: ENV.analytics.course
  ))

  participation.loadCourse ENV.analytics.course, [ENV.analytics.user], (courseData) ->
    courseData.drawPageViews "participating-graph", 500, 100, ENV.analytics.startDate, ENV.analytics.endDate

  assignments.loadCourse ENV.analytics.course, [ENV.analytics.user], (courseData) ->
    courseData.drawAssignmentTardiness "assignment-finishing-graph", 500, 100, ENV.analytics.startDate, ENV.analytics.endDate
    courseData.drawGrades "grades-graph", 500, 100, ENV.analytics.startDate, ENV.analytics.endDate
