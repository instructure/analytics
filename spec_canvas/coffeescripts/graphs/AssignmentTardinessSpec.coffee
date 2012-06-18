define ['jquery', 'analytics/compiled/graphs/assignment_tardiness'], ($, AssignmentTardiness) ->
  module 'Finishing Assignments graph',
    setup: ->
      @$el = $("<div id='tardiness-graph'/>")

  tolerantEqual = (actual, expected, tolerance, message) ->
    tolerance ?= 0.001
    message ?= "expected #{actual} to be within #{tolerance} of #{expected}"
    ok Math.abs(actual - expected) < tolerance, message

  test 'dateX: on startDate or endDate', ->
    startDate = new Date(2012, 0, 1)
    endDate = startDate.clone().addDays(10)
    examples = [
      { date: startDate, expected: 0 }
      { date: startDate.clone().addDays(3), expected: 30 }
      { date: startDate.clone().addDays(7), expected: 70 }
      { date: endDate, expected: 100 }
    ]

    graph = new AssignmentTardiness @$el,
      margin: 0
      padding: 0
      width: 100
      height: 100
      startDate: startDate
      endDate: endDate

    for example in examples
      tolerantEqual graph.dateX(example.date), example.expected

  test 'dateX: equal day spacing across +DST', ->
    startDate = new Date(2012, 2, 9) # Mar 9
    endDate = new Date(2012, 2, 13) # Mar 13
    examples = [
      { date: new Date(2012, 2, 10), expected: 25 } # Mar 10
      { date: new Date(2012, 2, 11), expected: 50 } # Mar 11, DST starts
      { date: new Date(2012, 2, 12), expected: 75 } # Mar 12
    ]

    graph = new AssignmentTardiness @$el,
      margin: 0
      padding: 0
      width: 100
      height: 100
      startDate: startDate
      endDate: endDate

    for example in examples
      tolerantEqual graph.dateX(example.date), example.expected

  test 'dateX: equal day spacing across -DST', ->
    startDate = new Date(2012, 10, 2) # Nov 2
    endDate = new Date(2012, 10, 6) # Nov 6
    examples = [
      { date: new Date(2012, 10, 3), expected: 25 } # Nov 3
      { date: new Date(2012, 10, 4), expected: 50 } # Nov 4, DST ends
      { date: new Date(2012, 10, 5), expected: 75 } # Nov 5
    ]

    graph = new AssignmentTardiness @$el,
      margin: 0
      padding: 0
      width: 100
      height: 100
      startDate: startDate
      endDate: endDate

    for example in examples
      tolerantEqual graph.dateX(example.date), example.expected

  test 'dateX: intra-day spacing (nominal)', ->
    startDate = new Date(2012, 6, 1)
    endDate = new Date(2012, 6, 2)
    examples = [
      { date: new Date(2012, 6, 1, 1, 0, 0), expected: 100 * 1 / 24 }
      { date: new Date(2012, 6, 1, 2, 0, 0), expected: 100 * 2 / 24 }
      { date: new Date(2012, 6, 1, 3, 0, 0), expected: 100 * 3 / 24 }
      { date: new Date(2012, 6, 1, 6, 0, 0), expected: 100 * 6 / 24 }
      { date: new Date(2012, 6, 1, 16, 0, 0), expected: 100 * 16 / 24 }
    ]

    graph = new AssignmentTardiness @$el,
      margin: 0
      padding: 0
      width: 100
      height: 100
      startDate: startDate
      endDate: endDate

    for example in examples
      tolerantEqual graph.dateX(example.date), example.expected

  # TODO: find out how to make these next two tests properly detect and skip
  # UTC, then uncomment.

  #test 'dateX: intra-day spacing on +DST', ->
  #  startDate = new Date(2012, 2, 11) # Mar 11, DST starts (23 hour day)
  #  endDate = new Date(2012, 2, 12)

  #  # if the test is running in a TZ that doesn't have DST (e.g. UTC), the
  #  # following specs will fail. we don't currently have a way to force DST
  #  # on, so just skip it.
  #  return if endDate - startDate is 24 * 60 * 1000

  #  examples = [
  #    { date: new Date(2012, 2, 11, 1, 0, 0), expected: 100 * 1 / 23 } # 1am = 1 hour in
  #    { date: new Date(2012, 2, 11, 2, 0, 0), expected: 100 * 1 / 23 } # 2am = 1 hour in (doesn't exist, treated as 1am)
  #    { date: new Date(2012, 2, 11, 3, 0, 0), expected: 100 * 2 / 23 } # 3am = 2 hours in (skipped the 2am hour)
  #    { date: new Date(2012, 2, 11, 6, 0, 0), expected: 100 * 5 / 23 } # 6am = 5 hours in
  #    { date: new Date(2012, 2, 11, 16, 0, 0), expected: 100 * 15 / 23 } # 4pm = 15 hours in
  #  ]

  #  graph = new AssignmentTardiness @$el,
  #    margin: 0
  #    padding: 0
  #    width: 100
  #    height: 100
  #    startDate: startDate
  #    endDate: endDate

  #  for example in examples
  #    tolerantEqual graph.dateX(example.date), example.expected

  #test 'dateX: intra-day spacing on -DST', ->
  #  startDate = new Date(2012, 10, 4) # Nov 4, DST ends (25 hour day)
  #  endDate = new Date(2012, 10, 5)

  #  # if the test is running in a TZ that doesn't have DST (e.g. UTC), the
  #  # following specs will fail. we don't currently have a way to force DST
  #  # on, so just skip it.
  #  return if endDate - startDate is 24 * 60 * 1000

  #  examples = [
  #    { date: new Date(2012, 10, 4, 0, 0, 0).addMinutes(60), expected: 100 * 1 / 25 } # first 1am = 1 hour in
  #    { date: new Date(2012, 10, 4, 1, 0, 0), expected: 100 * 2 / 25 } # second 1am = 2 hours in
  #    { date: new Date(2012, 10, 4, 2, 0, 0), expected: 100 * 3 / 25 } # 2am = 3 hours in
  #    { date: new Date(2012, 10, 4, 6, 0, 0), expected: 100 * 7 / 25 } # 6am = 7 hours in
  #    { date: new Date(2012, 10, 4, 16, 0, 0), expected: 100 * 17 / 25 } # 4pm = 17 hours in
  #  ]

  #  graph = new AssignmentTardiness @$el,
  #    margin: 0
  #    padding: 0
  #    width: 100
  #    height: 100
  #    startDate: startDate
  #    endDate: endDate

  #  for example in examples
  #    tolerantEqual graph.dateX(example.date), example.expected

  test 'colors', ->
    # set up date spectrum and freeze time
    dates =
      start:  new Date(2000, 0, 1)
      past:   new Date(2000, 1, 1)
      now:    new Date(2000, 1, 14)
      future: new Date(2000, 2, 1)
      end:    new Date(2000, 3, 1)
    clock = @sandbox.useFakeTimers +dates.now

    # setup color map
    colors =
      undated: "undated"
      onTime:  "onTime"
      late:    "late"
      missing: "missing"
      none:    "none"

    # create graph instance
    graph = new AssignmentTardiness @$el,
      width: 100
      height: 100
      startDate: dates.start
      endDate: dates.end
      diamondColorUndated: colors.undated
      diamondColorOnTime: colors.onTime
      diamondColorLate: colors.late
      diamondColorMissing: colors.missing
      barColorOnTime: colors.onTime
      barColorLate: colors.late

    # exercise colors method for combinations of dueAt/submittedAt (onTime
    # matches what it would be in real assignments given dueAt/submittedAt)
    deepEqual graph.colors(dueAt: null, submittedAt: null, onTime: true),
      barColor: colors.none
      diamondColor: colors.undated
      diamondFill: false

    deepEqual graph.colors(dueAt: null, submittedAt: dates.past, onTime: true),
      barColor: colors.none
      diamondColor: colors.undated
      diamondFill: true

    deepEqual graph.colors(dueAt: null, submittedAt: dates.future, onTime: true),
      barColor: colors.none
      diamondColor: colors.undated
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.past, submittedAt: null, onTime: null),
      barColor: colors.none
      diamondColor: colors.missing
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.future, submittedAt: null, onTime: null),
      barColor: colors.none
      diamondColor: colors.undated
      diamondFill: false

    deepEqual graph.colors(dueAt: dates.past, submittedAt: dates.past, onTime: true),
      barColor: colors.onTime
      diamondColor: colors.onTime
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.past, submittedAt: dates.now, onTime: false),
      barColor: colors.late
      diamondColor: colors.late
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.now, submittedAt: dates.now, onTime: true),
      barColor: colors.onTime
      diamondColor: colors.onTime
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.now, submittedAt: dates.future, onTime: false),
      barColor: colors.late
      diamondColor: colors.late
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.future, submittedAt: dates.past, onTime: true),
      barColor: colors.onTime
      diamondColor: colors.onTime
      diamondFill: true

    deepEqual graph.colors(dueAt: dates.future, submittedAt: dates.future, onTime: true),
      barColor: colors.onTime
      diamondColor: colors.onTime
      diamondFill: true
