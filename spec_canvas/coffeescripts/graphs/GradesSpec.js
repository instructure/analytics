import $ from 'jquery'
import Grades from '../../../app/jsx/graphs/grades'

QUnit.module('Grades graph')

test('scaleToAssignments with all zeroes: should not have Infinity as pointSpacing', () => {
  const $el = $("<div id='grades-graph'/>")
  const gradesGraph = new Grades($el, {
    width: 100,
    height: 100,
    margin: 0,
    padding: 0,
    bottomPadding: 0
  })

  gradesGraph.scaleToAssignments([
    {
      scoreDistribution: {
        maxScore: 0
      }
    }
  ])

  equal(gradesGraph.pointSpacing, gradesGraph.height)
})

test('scaleToAssignments with empty assignment: should look to other assignments for pointSpacing', () => {
  const goodAssignment = {
    title: 'Good Assignment',
    pointsPossible: 10
  }

  const emptyAssignment = {title: 'Empty Assignment'}

  const $el = $("<div id='grades-graph'/>")
  const gradesGraph = new Grades($el, {
    width: 100,
    height: 100,
    margin: 0,
    padding: 0
  })

  gradesGraph.scaleToAssignments([goodAssignment, emptyAssignment])

  equal(gradesGraph.yAxis.max, goodAssignment.pointsPossible)
})

QUnit.module('Assignment tooltip', hooks => {
  let $el
  let gradesGraph
  let oldRaw

  hooks.beforeEach(() => {
    const startDate = new Date(2022, 0, 1)
    const endDate = startDate.clone().addDays(5)

    // $.raw may or may not be defined at this point, depending on whether
    // we're running these tests as part of Canvas. Make sure there's something
    // here regardless.
    oldRaw = $.raw
    $.raw = string => string

    $el = $("<div id='grades-graph'/>")
    gradesGraph = new Grades($el, {
      endDate,
      height: 100,
      margin: 0,
      padding: 0,
      startDate,
      width: 100
    })
  })

  hooks.afterEach(() => {
    $.raw = oldRaw
  })

  test('includes the title of the assignment', () => {
    const assignment = {
      title: 'my assignment'
    }
    ok(gradesGraph.tooltip(assignment).includes('my assignment'))
  })

  test('displays aggregate score data if scoreDistribution is present', () => {
    const assignment = {
      scoreDistribution: {
        maxScore: 20,
        median: 15,
        minScore: 10
      },
      title: 'my assignment'
    }
    ok(gradesGraph.tooltip(assignment).includes('High: 20'))
  })

  test('does not show aggregate data if scoreDistribution is not present', () => {
    const assignment = {
      title: 'my assignment'
    }
    notOk(gradesGraph.tooltip(assignment).includes('High: 20'))
  })

  test('displays the student score if it is present alongside aggregate data', () => {
    const assignment = {
      muted: false,
      pointsPossible: 20,
      scoreDistribution: {
        maxScore: 20,
        median: 15,
        minScore: 10
      },
      studentScore: 10,
      title: 'my assignment'
    }
    ok(gradesGraph.tooltip(assignment).includes('Score: 10 &#x2F; 20'))
  })

  test('displays the student score if one exists but no aggregate data is present', () => {
    const assignment = {
      muted: false,
      pointsPossible: 20,
      studentScore: 10,
      title: 'my assignment'
    }
    ok(gradesGraph.tooltip(assignment).includes('Score: 10'))
  })

  test('indicates that the submission is hidden if "muted" is true', () => {
    const assignment = {
      muted: true,
      studentScore: 10,
      title: 'my assignment'
    }
    ok(gradesGraph.tooltip(assignment).includes('(hidden)'))
  })

  test('does not indicate that the submission is hidden if "muted" is false', () => {
    const assignment = {
      muted: false,
      studentScore: 10,
      title: 'my assignment'
    }
    notOk(gradesGraph.tooltip(assignment).includes('(hidden)'))
  })
})
