import $ from 'jquery'
import AssignmentTardiness from '../../../app/jsx/graphs/assignment_tardiness'

QUnit.module('Finishing Assignments graph', {
  setup() {
    this.$el = $("<div id='tardiness-graph'/>")
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

const width = 100

const indent = days => width / (days + 1) / 1.2 / 2

const spacing = days => (width - 2 * indent(days)) / days

const expectedX = (index, days) => indent(days) + index * spacing(days)

test('dateX: on startDate or endDate', function() {
  const startDate = new Date(2012, 0, 1)
  const endDate = startDate.clone().addDays(5)
  const examples = [
    {date: startDate, expected: expectedX(0, 5)},
    {date: startDate.clone().addDays(1), expected: expectedX(1, 5)},
    {date: startDate.clone().addDays(4), expected: expectedX(4, 5)},
    {date: endDate, expected: expectedX(5, 5)}
  ]

  const graph = new AssignmentTardiness(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  return Array.from(examples).map(example =>
    tolerantEqual(graph.dateX(example.date), example.expected)
  )
})

test('dateX: equal day spacing across +DST', function() {
  const startDate = new Date(2012, 2, 9) // Mar 9
  const endDate = new Date(2012, 2, 13) // Mar 13
  const examples = [
    {date: new Date(2012, 2, 10), expected: expectedX(1, 4)}, // Mar 10
    {date: new Date(2012, 2, 11), expected: expectedX(2, 4)}, // Mar 11, DST starts
    {date: new Date(2012, 2, 12), expected: expectedX(3, 4)} // Mar 12
  ]

  const graph = new AssignmentTardiness(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  return Array.from(examples).map(example =>
    tolerantEqual(graph.dateX(example.date), example.expected)
  )
})

test('dateX: equal day spacing across -DST', function() {
  const startDate = new Date(2012, 10, 2) // Nov 2
  const endDate = new Date(2012, 10, 6) // Nov 6
  const examples = [
    {date: new Date(2012, 10, 3), expected: expectedX(1, 4)}, // Nov 3
    {date: new Date(2012, 10, 4), expected: expectedX(2, 4)}, // Nov 4, DST ends
    {date: new Date(2012, 10, 5), expected: expectedX(3, 4)} // Nov 5
  ]

  const graph = new AssignmentTardiness(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  return Array.from(examples).map(example =>
    tolerantEqual(graph.dateX(example.date), example.expected)
  )
})

test('dateX: intra-day spacing (nominal)', function() {
  const startDate = new Date(2012, 6, 1)
  const endDate = new Date(2012, 6, 2)
  const examples = [
    {date: new Date(2012, 6, 1, 1, 0, 0), expected: expectedX(1 / 24, 1)},
    {date: new Date(2012, 6, 1, 2, 0, 0), expected: expectedX(2 / 24, 1)},
    {date: new Date(2012, 6, 1, 3, 0, 0), expected: expectedX(3 / 24, 1)},
    {date: new Date(2012, 6, 1, 6, 0, 0), expected: expectedX(6 / 24, 1)},
    {date: new Date(2012, 6, 1, 16, 0, 0), expected: expectedX(16 / 24, 1)}
  ]

  const graph = new AssignmentTardiness(this.$el, {
    margin: 0,
    padding: 0,
    width,
    height: 100,
    startDate,
    endDate
  })

  return Array.from(examples).map(example =>
    tolerantEqual(graph.dateX(example.date), example.expected)
  )
})

// TODO: find out how to make these next two tests properly detect and skip
// UTC, then uncomment.

// test 'dateX: intra-day spacing on +DST', ->
//  startDate = new Date(2012, 2, 11) # Mar 11, DST starts (23 hour day)
//  endDate = new Date(2012, 2, 12)

//  # if the test is running in a TZ that doesn't have DST (e.g. UTC), the
//  # following specs will fail. we don't currently have a way to force DST
//  # on, so just skip it.
//  return if endDate - startDate is 24 * 60 * 1000

//  examples = [
//    { date: new Date(2012, 2, 11, 1, 0, 0), expected: expectedX(1 / 23, 1) } # 1am = 1 hour in
//    { date: new Date(2012, 2, 11, 2, 0, 0), expected: expectedX(1 / 23, 1) } # 2am = 1 hour in (doesn't exist, treated as 1am)
//    { date: new Date(2012, 2, 11, 3, 0, 0), expected: expectedX(2 / 23, 1) } # 3am = 2 hours in (skipped the 2am hour)
//    { date: new Date(2012, 2, 11, 6, 0, 0), expected: expectedX(5 / 23, 1) } # 6am = 5 hours in
//    { date: new Date(2012, 2, 11, 16, 0, 0), expected: expectedX(15 / 23, 1) } # 4pm = 15 hours in
//  ]

//  graph = new AssignmentTardiness @$el,
//    margin: 0
//    padding: 0
//    width: width
//    height: 100
//    startDate: startDate
//    endDate: endDate

//  for example in examples
//    tolerantEqual graph.dateX(example.date), example.expected

// test 'dateX: intra-day spacing on -DST', ->
//  startDate = new Date(2012, 10, 4) # Nov 4, DST ends (25 hour day)
//  endDate = new Date(2012, 10, 5)

//  # if the test is running in a TZ that doesn't have DST (e.g. UTC), the
//  # following specs will fail. we don't currently have a way to force DST
//  # on, so just skip it.
//  return if endDate - startDate is 24 * 60 * 1000

//  examples = [
//    { date: new Date(2012, 10, 4, 0, 0, 0).addMinutes(60), expected: expectedX(1 / 25, 1) } # first 1am = 1 hour in
//    { date: new Date(2012, 10, 4, 1, 0, 0), expected: expectedX(2 / 25, 1) } # second 1am = 2 hours in
//    { date: new Date(2012, 10, 4, 2, 0, 0), expected: expectedX(3 / 25, 1) } # 2am = 3 hours in
//    { date: new Date(2012, 10, 4, 6, 0, 0), expected: expectedX(7 / 25, 1) } # 6am = 7 hours in
//    { date: new Date(2012, 10, 4, 16, 0, 0), expected: expectedX(17 / 25, 1) } # 4pm = 17 hours in
//  ]

//  graph = new AssignmentTardiness @$el,
//    margin: 0
//    padding: 0
//    width: width
//    height: 100
//    startDate: startDate
//    endDate: endDate

//  for example in examples
//    tolerantEqual graph.dateX(example.date), example.expected

test('colors', function() {
  // set up date spectrum and freeze time
  const dates = {
    start: new Date(2000, 0, 1),
    past: new Date(2000, 1, 1),
    now: new Date(2000, 1, 14),
    future: new Date(2000, 2, 1),
    end: new Date(2000, 3, 1)
  }
  const clock = sinon.useFakeTimers(+dates.now)

  // setup color map
  const colors = {
    undated: 'undated',
    onTime: 'onTime',
    late: 'late',
    missing: 'missing',
    empty: 'empty',
    none: 'none'
  }

  // create graph instance
  const graph = new AssignmentTardiness(this.$el, {
    width,
    height: 100,
    startDate: dates.start,
    endDate: dates.end,
    colorUndated: colors.undated,
    colorOnTime: colors.onTime,
    colorLate: colors.late,
    colorMissing: colors.missing,
    colorEmpty: colors.empty
  })

  // exercise shape_attrs method for combinations of dueAt/submittedAt (onTime
  // matches what it would be in real assignments given dueAt/submittedAt)
  deepEqual(graph.shape_attrs({dueAt: null, submittedAt: null, onTime: true}), {
    shape: 'circle',
    color: colors.undated,
    fill: colors.empty
  })

  deepEqual(graph.shape_attrs({dueAt: null, submittedAt: dates.past, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  deepEqual(graph.shape_attrs({dueAt: null, submittedAt: dates.future, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  deepEqual(graph.shape_attrs({dueAt: dates.past, submittedAt: null, onTime: null}), {
    shape: 'square',
    color: colors.missing,
    fill: colors.missing
  })

  deepEqual(graph.shape_attrs({dueAt: dates.future, submittedAt: null, onTime: null}), {
    shape: 'circle',
    color: colors.undated,
    fill: colors.empty
  })

  deepEqual(graph.shape_attrs({dueAt: dates.past, submittedAt: dates.past, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  deepEqual(graph.shape_attrs({dueAt: dates.past, submittedAt: dates.now, onTime: false}), {
    shape: 'triangle',
    color: colors.late,
    fill: colors.late
  })

  deepEqual(graph.shape_attrs({dueAt: dates.now, submittedAt: dates.now, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  deepEqual(graph.shape_attrs({dueAt: dates.now, submittedAt: dates.future, onTime: false}), {
    shape: 'triangle',
    color: colors.late,
    fill: colors.late
  })

  deepEqual(graph.shape_attrs({dueAt: dates.future, submittedAt: dates.past, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  deepEqual(graph.shape_attrs({dueAt: dates.future, submittedAt: dates.future, onTime: true}), {
    shape: 'circle',
    color: colors.onTime,
    fill: colors.onTime
  })

  clock.restore()
})

QUnit.module('Assignment tooltip', hooks => {
  let $el
  let tardinessGraph
  let oldRaw

  hooks.beforeEach(() => {
    const startDate = new Date(2022, 0, 1)
    const endDate = startDate.clone().addDays(5)

    // $.raw may or may not be defined at this point, depending on whether
    // we're running these tests as part of Canvas. Make sure there's something
    // here regardless.
    oldRaw = $.raw
    $.raw = string => string

    $el = $("<div id='tardiness-graph'/>")
    tardinessGraph = new AssignmentTardiness($el, {
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
    ok(tardinessGraph.tooltip(assignment).includes('my assignment'))
  })

  test('indicates that the score is hidden if "muted" is true', () => {
    const assignment = {
      muted: true,
      studentScore: 10,
      title: 'my assignment'
    }
    ok(tardinessGraph.tooltip(assignment).includes('Score: (hidden)'))
  })

  test('displays the student score if a score exists', () => {
    const assignment = {
      muted: false,
      studentScore: 10,
      title: 'my assignment'
    }
    ok(tardinessGraph.tooltip(assignment).includes('Score: 10'))
  })
})
