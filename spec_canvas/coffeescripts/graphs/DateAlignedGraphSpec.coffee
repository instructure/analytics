define ['jquery', 'analytics/compiled/graphs/DateAlignedGraph', 'translations/_core_en'], ($, DateAlignedGraph) ->
  module 'DateAlignedGraph',
    setup: ->
      @$el = $("<div/>")

  tolerantEqual = (actual, expected, tolerance, message) ->
    tolerance ?= 0.001
    message ?= "expected #{actual} to be within #{tolerance} of #{expected}"
    ok Math.abs(actual - expected) < tolerance, message

  width = 100
  expectedX = (index, days) ->
    indent = width / (days + 1) / 1.2 / 2
    spacing = (width - 2 * indent) / days
    indent + index * spacing

  test 'dateX', ->
    startDate = new Date(2012, 0, 1)
    endDate = startDate.clone().addDays(10)
    examples = [
      { date: startDate, expected: expectedX(0, 10) }
      { date: startDate.clone().addDays(3), expected: expectedX(3, 10) }
      { date: startDate.clone().addDays(7), expected: expectedX(7, 10) }
      { date: endDate, expected: expectedX(10, 10) }
    ]

    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate

    for example in examples
      tolerantEqual graph.dateX(example.date), example.expected

  test 'drawDateAxis', ->
    startDate = new Date(2012, 0, 1) # Sunday
    endDate = startDate.clone().addDays(15) # Monday
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    tickSpy = sinon.spy(graph, 'drawDayTick')
    weekSpy = sinon.spy(graph, 'drawWeekLine')
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # should draw week lines at each monday
    mondays = [
      expectedX(1, 15)
      expectedX(8, 15)
      expectedX(15, 15)
    ]
    equal weekSpy.callCount, mondays.length
    for i in [0...mondays.length]
      equal weekSpy.args[i], mondays[i]

    # should draw day labels on each monday, but month labels only on the first
    # monday
    labels = [
      [ expectedX(1, 15), 110, 2 ]
      [ expectedX(1, 15), -10, 'Jan 2012' ]
      [ expectedX(8, 15), 110, 9 ]
      [ expectedX(15, 15), 110, 16 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

    # should draw ticks on each day
    ticks = $.map [0..15], (i) -> expectedX(i, 15)
    equal tickSpy.callCount, ticks.length
    for i in [0...ticks.length]
      equal tickSpy.args[i], ticks[i]

  test 'drawDateAxis: spanning months', ->
    startDate = new Date(2012, 0, 29) # Sunday
    endDate = startDate.clone().addDays(15) # Monday
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # both mondays should have month labels, but the second should not include
    # the year
    labels = [
      [ expectedX(1, 15), 110, 30 ]
      [ expectedX(1, 15), -10, 'Jan 2012' ]
      [ expectedX(8, 15), 110, 6 ]
      [ expectedX(8, 15), -10, 'Feb' ]
      [ expectedX(15, 15), 110, 13 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

  test 'drawDateAxis: spanning years', ->
    startDate = new Date(2011, 11, 25) # Sunday
    endDate = startDate.clone().addDays(15) # Monday
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # both mondays should have month labels with years
    labels = [
      [ expectedX(1, 15), 110, 26 ]
      [ expectedX(1, 15), -10, 'Dec 2011' ]
      [ expectedX(8, 15), 110, 2 ]
      [ expectedX(8, 15), -10, 'Jan 2012' ]
      [ expectedX(15, 15), 110, 9 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]
