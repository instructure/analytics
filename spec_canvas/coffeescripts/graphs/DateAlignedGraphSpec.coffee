define ['jquery', 'analytics/compiled/graphs/DateAlignedGraph', 'translations/_core_en'], ($, DateAlignedGraph) ->
  QUnit.module 'DateAlignedGraph',
    setup: ->
      @$el = $("<div/>")

  tolerantEqual = (actual, expected, tolerance, message) ->
    tolerance ?= 0.001
    message ?= "expected #{actual} to be within #{tolerance} of #{expected}"
    ok Math.abs(actual - expected) < tolerance, message

  width = 200
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

  test 'dateX: values out of range', ->
    startDate = new Date(2012, 0, 1) # Sunday
    endDate = startDate.clone().addDays(5) # Monday
    graph = new DateAlignedGraph @$el,
      margin: 10
      padding: 5
      width: width
      height: 100
      startDate: startDate
      endDate: endDate

    leftOutOfBoundsDate = startDate.clone().addDays(-1)
    rightOutOfBoundsDate = endDate.clone().addDays(1)
    equal 10, graph.dateX(leftOutOfBoundsDate)
    equal true, graph.clippedDate
    graph.clippedDate = false

    equal 210, graph.dateX(rightOutOfBoundsDate)
    equal true, graph.clippedDate

  test 'drawDateAxis', ->
    startDate = new Date(2016, 1, 28) # Sunday, Feb 28, 2016 (0-based month)
    endDate = startDate.clone().addDays(4)
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

    # should draw day labels on each day, but month labels only
    # if it doesn't match the previous month
    labels = [
      [ expectedX(0, 4), 100, 'Feb 28' ]
      [ expectedX(1, 4), 100, 29 ]
      [ expectedX(2, 4), 100, 'Mar 1' ]
      [ expectedX(3, 4), 100, 2 ]
      [ expectedX(4, 4), 100, 3 ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

  test 'drawDateAxis: spanning months', ->
    startDate = new Date(2016, 1, 28)
    endDate = startDate.clone().addDays(45)
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

    # both months should have labels, but the second should not include the year
    labels = [
      [ expectedX(2, 7), 100, 'Mar 2016' ]
      [ expectedX(6, 7), 100, 'Apr' ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

  test 'drawDateAxis: spanning years', ->
    startDate = new Date(2015, 10, 25)
    endDate = startDate.clone().addDays(45)
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

    # both months should have month labels with years
    labels = [
      [ expectedX(2, 6), 100, 'Dec 2015' ]
      [ expectedX(6, 6), 100, 'Jan 2016' ]
    ]
    equal labelSpy.callCount, labels.length
    for i in [0...labels.length]
      deepEqual labelSpy.args[i], labels[i]

  test 'binDateText, day binner', ->
    startDate = new Date(2015, 0, 1)
    endDate = startDate.clone().addDays(5)
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate
    equal graph.binDateText(date: startDate), 'Jan 1, 2015'
    equal graph.binDateText(date: graph.binner.nextTick(startDate)), 'Jan 2, 2015'

  test "binDateText, week binner", ->
    startDate = new Date(2015, 0, 1)
    endDate = startDate.clone().addDays(30)
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate
    equal graph.binDateText(date: startDate), 'Jan 1 - Jan 7, 2015'
    equal graph.binDateText(date: graph.binner.nextTick(startDate)), 'Jan 8 - Jan 14, 2015'

  test "binDateText, week binner, spanning years", ->
    startDate = new Date(2015, 11, 28)
    endDate = startDate.clone().addDays(30)
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate
    equal graph.binDateText(date: startDate), 'Dec 28, 2015 - Jan 3, 2016'
    equal graph.binDateText(date: graph.binner.nextTick(startDate)), 'Jan 4 - Jan 10, 2016'

  test "binDateText, month binner", ->
    startDate = new Date(2015, 3, 15)
    endDate = startDate.clone().addDays(500)
    graph = new DateAlignedGraph @$el,
      margin: 0
      padding: 0
      width: width
      height: 100
      startDate: startDate
      endDate: endDate
    equal graph.binDateText(date: startDate), 'Apr 2015'
    equal graph.binDateText(date: graph.binner.nextTick(startDate)), 'May 2015'