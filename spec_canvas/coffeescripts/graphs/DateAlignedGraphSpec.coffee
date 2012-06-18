define ['jquery', 'analytics/compiled/graphs/DateAlignedGraph', 'translations/_core_en'], ($, DateAlignedGraph) ->
  module 'DateAlignedGraph',
    setup: ->
      @$el = $("<div/>")

  tolerantEqual = (actual, expected, tolerance, message) ->
    tolerance ?= 0.001
    message ?= "expected #{actual} to be within #{tolerance} of #{expected}"
    ok Math.abs(actual - expected) < tolerance, message

  test 'dateX', ->
    startDate = new Date(2012, 0, 1)
    endDate = startDate.clone().addDays(10)
    examples = [
      { date: startDate, expected: 0 }
      { date: startDate.clone().addDays(3), expected: 30 }
      { date: startDate.clone().addDays(7), expected: 70 }
      { date: endDate, expected: 100 }
    ]

    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: 100
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
      width: 150
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    tickSpy = sinon.spy(graph, 'drawDayTick')
    weekSpy = sinon.spy(graph, 'drawWeekLine')
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # should draw week lines at each monday
    mondays = [ 10, 80, 150 ]
    equal weekSpy.callCount, mondays.length
    for i in [0...mondays.length]
      equal weekSpy.args[i], mondays[i]

    # should draw day labels on each monday, but month labels only on the first
    # monday
    labels = [
      [ 10, 110, 2 ]
      [ 10, -10, 'Jan 2012' ]
      [ 80, 110, 9 ]
      [ 150, 110, 16 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

    # should draw ticks on each day
    ticks = $.map [0..15], (i) -> i * 10
    equal tickSpy.callCount, ticks.length
    for i in [0...ticks.length]
      equal tickSpy.args[i], ticks[i]

  test 'drawDateAxis: spanning months', ->
    startDate = new Date(2012, 0, 29) # Sunday
    endDate = startDate.clone().addDays(15) # Monday
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: 150
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # both mondays should have month labels, but the second should not include
    # the year
    labels = [
      [ 10, 110, 30 ]
      [ 10, -10, 'Jan 2012' ]
      [ 80, 110, 6 ]
      [ 80, -10, 'Feb' ]
      [ 150, 110, 13 ]
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
      width: 150
      height: 100
      startDate: startDate
      endDate: endDate

    # draw the axis
    labelSpy = sinon.spy(graph, 'dateLabel')
    graph.drawDateAxis()

    # both mondays should have month labels with years
    labels = [
      [ 10, 110, 26 ]
      [ 10, -10, 'Dec 2011' ]
      [ 80, 110, 2 ]
      [ 80, -10, 'Jan 2012' ]
      [ 150, 110, 9 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]
