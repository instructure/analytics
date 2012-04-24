# baseUrl in this context is public/javascripts
require.config
  paths:
    analytics: "../plugins/analytics/javascripts"

define ['jquery', 'analytics/compiled/graphs/grades'], ($, Grades) ->
  module 'Grades graph'

  test 'scaleToAssignments with all zeroes: should not have Infinity as pointSpacing', ->
    $el = $("<div id='grades-graph'/>")
    gradesGraph = new Grades $el,
      width: 100
      height: 100
      margin: 0
      padding: 0

    gradesGraph.scaleToAssignments [
      scoreDistribution:
        maxScore: 0
    ]

    equal gradesGraph.pointSpacing, gradesGraph.height
