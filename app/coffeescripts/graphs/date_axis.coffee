define [ 'i18nObj', 'use!underscore' ], (I18n, _) ->

  ##
  # Return the date n days before or after (depending on sign of n) the date.
  daysFrom = (date, n) ->
    # even if this makes this > last day of month or < 1, setDate is smart
    # about it and just wraps over to the next month.
    date = new Date(date)
    date.setDate(date.getDate() + n)
    date

  ##
  # Determine the Monday before the given date. If the date is a monday, the
  # date is unchanged.
  mondayBefore = (date) ->
    # would use -1 instead of +6, but -1 % 7 == -1 instead of 6. and in a
    # correct system, -1 and +6 are equivalent mod 7.
    daysFrom(date, -(date.getDay() + 6) % 7)

  ##
  # Determine the Monday after the given date. If the date is a monday, the
  # date is unchanged.
  mondayAfter = (date) ->
    # would use 1 - instead of 8 -, but again, javascript is stupid about
    # negative modulos.
    daysFrom(date, (8 - date.getDay()) % 7)

  ##
  # Draws a label for the date in the bottom margin of the graph, centered on
  drawLabel = (date, graph, x, showMonth, showYear) ->
    if showMonth
      style = if showYear then "medium_month" else "short_month"
      month = graph.paper.text x, graph.topMargin - 10, I18n.l("date.formats.#{style}", date)
      month.attr fill: graph.frameColor
    day = graph.paper.text x, graph.topMargin + graph.height + 10, date.getDate()
    day.attr fill: graph.frameColor

  ##
  # Draws a gridColor line the full height of the graph at that x, if the graph
  # has a gridColor.
  drawGrid = (date, graph, x, toggle) ->
    if graph.gridColor?
      gridLine = graph.paper.path [
        "M", x, graph.topMargin,
        "l", 0, graph.height ]
      gridLine.attr stroke: graph.gridColor

  ##
  # Draws day tick-marks on graph at x, coming from the top and bottom frames
  # half way into the padding.
  drawTick = (graph, x) ->
    ticks = graph.paper.path [
      "M", x, graph.topMargin,
      "l", 0, 5,
      "M", x, graph.topMargin + graph.height,
      "l", 0, -5 ]
    ticks.attr stroke: graph.frameColor

  ##
  # Draws an x-axis with daily ticks and weekly (on monday) labels on the given
  # graph. The graph must have a dateX(date) method and startDate and endDate
  # attributes.
  (graph) ->
    if !graph? || (typeof graph.dateX != "function") || !graph.startDate? || !graph.endDate?
      throw new Error "argument doesn't quack right"

    # draw grid lines
    firstMonday = mondayAfter graph.startDate
    lastMonday = mondayBefore graph.endDate
    mondayCount = Math.round((lastMonday - firstMonday) / (7 * 86400 * 1000)) + 1
    previousMonth = null
    previousYear = null
    for i in [0...mondayCount]
      monday = daysFrom firstMonday, i * 7
      x = graph.dateX monday
      drawGrid monday, graph, x
      thisMonth = monday.getMonth()
      thisYear = monday.getYear()
      showMonth = (previousMonth is null) || (previousMonth != thisMonth)
      showYear = (previousYear is null) || (previousYear != thisYear)
      drawLabel monday, graph, x, showMonth, showYear
      previousMonth = thisMonth
      previousYear = thisYear

    # draw tick marks
    dayCount = Math.round((graph.endDate - graph.startDate) / (86400 * 1000)) + 1
    days = (daysFrom(graph.startDate, i) for i in [0...dayCount])
    _.each days, (day) -> drawTick(graph, graph.dateX day)
