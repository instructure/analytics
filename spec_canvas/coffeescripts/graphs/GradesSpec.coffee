define ['jquery', 'analytics/compiled/graphs/grades'], ($, Grades) ->
  QUnit.module 'Grades graph'

  test 'scaleToAssignments with all zeroes: should not have Infinity as pointSpacing', ->
    $el = $("<div id='grades-graph'/>")
    gradesGraph = new Grades $el,
      width: 100
      height: 100
      margin: 0
      padding: 0
      bottomPadding: 0

    gradesGraph.scaleToAssignments [
      scoreDistribution:
        maxScore: 0
    ]

    equal gradesGraph.pointSpacing, gradesGraph.height

  test 'scaleToAssignments with empty assignment: should look to other assignments for pointSpacing', ->
    goodAssignment =
      title: "Good Assignment"
      pointsPossible: 10

    emptyAssignment = 
      title: "Empty Assignment"

    $el = $("<div id='grades-graph'/>")
    gradesGraph = new Grades $el,
      width: 100
      height: 100
      margin: 0
      padding: 0

    gradesGraph.scaleToAssignments [goodAssignment, emptyAssignment]

    equal gradesGraph.yAxis.max, goodAssignment.pointsPossible
