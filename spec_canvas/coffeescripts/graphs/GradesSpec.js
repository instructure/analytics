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
