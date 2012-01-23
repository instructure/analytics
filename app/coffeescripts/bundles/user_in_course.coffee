require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/user_in_course'
  'analytics/compiled/models/participation'
  'analytics/compiled/models/messaging'
  'analytics/compiled/models/assignments'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/responsiveness'
  'analytics/compiled/graphs/assignment_tardiness'
  'analytics/compiled/graphs/grades'
], ($, template, Participation, Messaging, Assignments, PageViews, Responsiveness, AssignmentTardiness, Grades) ->

  # unpackage the environment
  {user, course, startDate, endDate} = ENV.ANALYTICS
  startDate = Date.parse(startDate)
  endDate = Date.parse(endDate)

  # populate the template and inject it into the page
  $("#analytics_body").append template {user, course}

  # setup the graphs
  graphOpts =
    width: 800
    height: 100

  dateGraphOpts = $.extend {}, graphOpts,
    startDate: startDate
    endDate: endDate
    leftPadding: 30  # larger padding on left because of assymetrical
    rightPadding: 15 # responsiveness bubbles

  pageViews = new PageViews "participating-graph", $.extend {}, dateGraphOpts,
    verticalPadding: 5

  responsiveness = new Responsiveness "responsiveness-graph", $.extend {}, dateGraphOpts,
    verticalPadding: 10
    gutterHeight: 25
    caratSize: 5

  assignmentTardiness = new AssignmentTardiness "assignment-finishing-graph", $.extend {}, dateGraphOpts,
    verticalPadding: 10

  grades = new Grades "grades-graph", $.extend {}, graphOpts,
    height: 200
    padding: 15

  # request data
  participation = new Participation course, user
  messaging = new Messaging course, user
  assignments = new Assignments course, user

  # draw graphs
  pageViews.graphDeferred participation.ready -> participation
  responsiveness.graphDeferred messaging.ready -> messaging
  assignmentTardiness.graphDeferred assignments.ready -> assignments
  grades.graphDeferred assignments.ready -> assignments
