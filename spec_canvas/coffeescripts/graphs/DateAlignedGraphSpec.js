import $ from 'jquery'
import DateAlignedGraph from '../../../app/jsx/graphs/DateAlignedGraph'
import coreTranslations from 'translations/en.json'
import {useTranslations} from '@canvas/i18n'

QUnit.module('DateAlignedGraph', {
  setup() {
    useTranslations('en', coreTranslations)
    this.$el = $('<div/>')
  }
})

const tolerantEqual = function(actual, expected, tolerance, message) {
  if (tolerance == null) {
    tolerance = 0.001
  }
  if (message == null) {
    message = `expected ${actual} to be within ${tolerance} of ${expected}`
  }
  ok(Math.abs(actual - expected) < tolerance, message)
}

const width = 200
const expectedX = function(index, days) {
  const indent = width / (days + 1) / 1.2 / 2
  const spacing = (width - 2 * indent) / days
  return indent + index * spacing
}

test('dateX', function() {
  const startDate = new Date(2012, 0, 1)
  const endDate = startDate.clone().addDays(10)
  const examples = [
    {date: startDate, expected: expectedX(0, 10)},
    {date: startDate.clone().addDays(3), expected: expectedX(3, 10)},
    {date: startDate.clone().addDays(7), expected: expectedX(7, 10)},
    {date: endDate, expected: expectedX(10, 10)}
  ]

  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })
  for (const example of examples) {
    tolerantEqual(graph.dateX(example.date), example.expected)
  }
})

test('dateX: values out of range', function() {
  const startDate = new Date(2012, 0, 1) // Sunday
  const endDate = startDate.clone().addDays(5) // Monday
  const graph = new DateAlignedGraph(this.$el, {
    margin: 10,
    padding: 5,
    width,
    height: 100,
    startDate,
    endDate
  })

  const leftOutOfBoundsDate = startDate.clone().addDays(-1)
  const rightOutOfBoundsDate = endDate.clone().addDays(1)
  equal(10, graph.dateX(leftOutOfBoundsDate))
  equal(true, graph.clippedDate)
  graph.clippedDate = false

  equal(210, graph.dateX(rightOutOfBoundsDate))
  equal(true, graph.clippedDate)
})

test('drawDateAxis', function() {
  const startDate = new Date(2016, 1, 28) // Sunday, Feb 28, 2016 (0-based month)
  const endDate = startDate.clone().addDays(4)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  // draw the axis
  const labelSpy = sinon.spy(graph, 'dateLabel')
  graph.drawDateAxis()

  // should draw day labels on each day, but month labels only
  // if it doesn't match the previous month
  const labels = [
    [expectedX(0, 4), 100, 'Feb 28'],
    [expectedX(1, 4), 100, 29],
    [expectedX(2, 4), 100, 'Mar 1'],
    [expectedX(3, 4), 100, 2],
    [expectedX(4, 4), 100, 3]
  ]
  equal(labelSpy.callCount, labels.length)
  __range__(0, labels.length, false).forEach(
    i => deepEqual(labelSpy.args[i], labels[i])
  )
})

test('drawDateAxis: spanning months', function() {
  const startDate = new Date(2016, 1, 28)
  const endDate = startDate.clone().addDays(45)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  // draw the axis
  const labelSpy = sinon.spy(graph, 'dateLabel')
  graph.drawDateAxis()

  // both months should have labels, but the second should not include the year
  const labels = [
    [expectedX(2, 7), 100, 'Mar 2016'],
    [expectedX(6, 7), 100, 'Apr']
  ]
  equal(labelSpy.callCount, labels.length)
  __range__(0, labels.length, false).forEach(
    i => deepEqual(labelSpy.args[i], labels[i])
  )
})

test('drawDateAxis: spanning years', function() {
  const startDate = new Date(2015, 10, 25)
  const endDate = startDate.clone().addDays(45)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  // draw the axis
  const labelSpy = sinon.spy(graph, 'dateLabel')
  graph.drawDateAxis()

  // both months should have month labels with years
  const labels = [[expectedX(2, 6), 100, 'Dec 2015'], [expectedX(6, 6), 100, 'Jan 2016']]
  equal(labelSpy.callCount, labels.length)
  __range__(0, labels.length, false).map(i => deepEqual(labelSpy.args[i], labels[i]))
})

test('binDateText, day binner', function() {
  const startDate = new Date(2015, 0, 1)
  const endDate = startDate.clone().addDays(5)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })
  equal(graph.binDateText({date: startDate}), 'Jan 1, 2015')
  equal(graph.binDateText({date: graph.binner.nextTick(startDate)}), 'Jan 2, 2015')
})

test('binDateText, week binner', function() {
  const startDate = new Date(2015, 0, 1)
  const endDate = startDate.clone().addDays(30)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })
  equal(graph.binDateText({date: startDate}), 'Jan 1 - Jan 7, 2015')
  equal(graph.binDateText({date: graph.binner.nextTick(startDate)}), 'Jan 8 - Jan 14, 2015')
})

test('binDateText, week binner, spanning years', function() {
  const startDate = new Date(2015, 11, 28)
  const endDate = startDate.clone().addDays(30)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })
  equal(graph.binDateText({date: startDate}), 'Dec 28, 2015 - Jan 3, 2016')
  equal(graph.binDateText({date: graph.binner.nextTick(startDate)}), 'Jan 4 - Jan 10, 2016')
})

test('binDateText, month binner', function() {
  const startDate = new Date(2015, 3, 15)
  const endDate = startDate.clone().addDays(500)
  const graph = new DateAlignedGraph(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })
  equal(graph.binDateText({date: startDate}), 'Apr 2015')
  equal(graph.binDateText({date: graph.binner.nextTick(startDate)}), 'May 2015')
})

function __range__(left, right, inclusive) {
  const range = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
