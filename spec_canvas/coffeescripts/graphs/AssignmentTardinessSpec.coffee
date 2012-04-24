# baseUrl in this context is public/javascripts
require.config
  paths:
    analytics: "../plugins/analytics/javascripts"

define ['jquery', 'analytics/compiled/graphs/assignment_tardiness'], ($, AssignmentTardiness) ->
  module 'Finishing Assignments graph',
    setup: ->
      @$el = $("<div id='tardiness-graph'/>")

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
