define [
  'underscore'
  'analytics/compiled/graphs/DateAlignedGraph'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/helpers'
  'i18nObj'
], (_, DateAlignedGraph, Cover, helpers, I18n) ->

  ##
  # AssignmentTardiness visualizes the student's ability to turn in assignments
  # on time. It displays one assignment per row, with the x-axis aligned to
  # time. An assignment is displayed in its row with a diamond on the due date
  # (or at the end of the row if there is no due date) and a bar representing
  # the time between the student's submission and the due date.

  defaultOptions =

    ##
    # The height of the submission bars, in pixels.
    barHeight: 8

    ##
    # The height of the due date diamonds, in pixels. Defaults to barHeight + 2
    # if unset.
    diamondHeight: null

    ##
    # The size of the vertical gutter between elements as a percent of the
    # height of those elements.
    gutterPercent: 0.25

    ##
    # Bar color for on time assignments.
    barColorOnTime: "lightgreen"

    ##
    # Diamond color for on time assignments.
    diamondColorOnTime: "darkgreen"

    ##
    # Bar color for late assignments.
    barColorLate: "lightyellow"

    ##
    # Diamond color for late assignments.
    diamondColorLate: "darkyellow"

    ##
    # Diamond color for missing assignments.
    diamondColorMissing: "red"

    ##
    # Diamond color for undated assignments.
    diamondColorUndated: "darkgray"

  class AssignmentTardiness extends DateAlignedGraph
    ##
    # Takes an element and options, same as for DateAlignedGraph. Recognizes
    # the options described above in addition to the options for
    # DateAlignedGraph.
    constructor: (div, options) ->
      super

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      @diamondHeight ?= @barHeight + 2
      @gutterHeight = @gutterPercent * @barHeight
      @barSpacing = @barHeight + @gutterHeight

      # middle of first bar
      @y0 = @topMargin + @topPadding + @diamondHeight / 2

    ##
    # Graph the assignments.
    graph: (assignments) =>
      return unless super

      assignments = assignments.assignments
      if !assignments? || assignments.length == 0
        # no data
        return

      @scaleToAssignments assignments
      @drawGrid assignments if @gridColor
      _.each assignments, @graphAssignment

    ##
    # Resize the graph vertically to accomodate the number of assigments.
    scaleToAssignments: (assignments) ->
      @resize height:
        @topPadding + (assignments.length - 1) * @barSpacing + @diamondHeight + @bottomPadding

    ##
    # Draws the gutters between the assignments.
    drawGrid: (assignments) ->
      for i in [0..assignments.length]
        @drawGridLine @gridY i

    drawGridLine: (y) ->
      gridline = @paper.path ["M", @leftMargin, y, "l", @width, 0]
      gridline.attr stroke: @gridColor

    gridY: (index) ->
      (@indexY index) - @barSpacing / 2

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, index) =>
      dueX = @dueX assignment
      submittedX = @submittedX assignment
      y = @indexY index
      colors = @colors assignment
      if submittedX? && submittedX != dueX
        @drawSubmittedBar dueX, submittedX, y, colors.barColor
      @drawDiamond dueX, y, colors.diamondColor, colors.diamondFill
      @cover dueX, y, assignment

    ##
    # Determine the colors to use for an assignment.
    colors: (assignment) ->
      if !assignment.dueAt?
        # no due date
        barColor: "none"
        diamondColor: @diamondColorUndated
        diamondFill: assignment.submittedAt?
      else if assignment.onTime is true
        # has due date, turned in on time
        barColor: @barColorOnTime
        diamondColor: @diamondColorOnTime
        diamondFill: true
      else if assignment.onTime is false
        # has due date, turned in late
        barColor: @barColorLate
        diamondColor: @diamondColorLate
        diamondFill: true
      else if assignment.dueAt > new Date
        # due in the future, not turned in
        barColor: "none"
        diamondColor: @diamondColorUndated
        diamondFill: false
      else
        # due in the past, not turned in
        barColor: "none"
        diamondColor: @diamondColorMissing
        diamondFill: true

    ##
    # Convert an assignment's due date to an x-coordinate. If no due date, use
    # submitted at. If no due date and not submitted, use the end date.
    dueX: (assignment) ->
      @dateX(assignment.dueAt ? assignment.submittedAt ? @endDate)

    ##
    # Convert an assignment's submitted at to an x-coordinate.
    submittedX: (assignment) ->
      if assignment.submittedAt?
        @dateX assignment.submittedAt
      else
        null

    ##
    # Convert a date to an x-coordinate.
    dateX: (datetime) ->
      floorDate = helpers.midnight datetime, 'floor'
      ceilDate = helpers.midnight datetime, 'ceil'
      floorX = super floorDate
      if ceilDate.equals floorDate
        floorX
      else
        ceilX = super ceilDate
        fraction = (datetime.getTime() - floorDate.getTime()) / (ceilDate.getTime() - floorDate.getTime())
        floorX + fraction * (ceilX - floorX)

    ##
    # Convert an assignment index to a y-coordinate.
    indexY: (index) ->
      @y0 + index * @barSpacing

    ##
    # Draw the bar representing the difference between submitted at and due
    # date.
    drawSubmittedBar: (x1, x2, y, color) ->
      [left, right] = if x1 < x2 then [x1, x2] else [x2, x1]
      bar = @paper.rect left, y - @barHeight / 2, right - left, @barHeight
      bar.attr fill: color, stroke: color

    ##
    # Draw the diamond representing the due date.
    drawDiamond: (x, y, color, fill) ->
      diamondTop = y - @diamondHeight / 2
      diamondBottom = y + @diamondHeight / 2
      diamondLeft = x - @diamondHeight / 2
      diamondRight = x + @diamondHeight / 2
      path = ["M", x, diamondTop,
              "L", diamondLeft, y,
              "L", x, diamondBottom,
              "L", diamondRight, y,
              "L", x, diamondTop,
              "z"]
      diamond = @paper.path path
      diamond.attr stroke: color, fill: (if fill then color else "none")

    ##
    # Create a tooltip for the assignment.
    cover: (x, y, assignment) ->
      new Cover this,
        region: @paper.rect @leftMargin, y - @barSpacing / 2, @width, @barSpacing
        classes: "assignment_#{assignment.id}"
        tooltip:
          contents: @tooltip assignment
          x: x
          y: y + @diamondHeight / 2
          direction: 'down'

    ##
    # Build the text for the assignment's tooltip.
    tooltip: (assignment) ->
      tooltip = assignment.title
      if assignment.dueAt?
        dueAtString = I18n.t 'time.due_date',
          date: I18n.l('date.formats.medium', assignment.dueAt)
          time: I18n.l('time.formats.tiny', assignment.dueAt)
        tooltip += "<br/>Due: #{dueAtString}"
      else
        tooltip += "<br/>(no due date)"
      if assignment.submittedAt?
        submittedAtString = I18n.t 'time.event',
          date: I18n.l('date.formats.medium', assignment.submittedAt)
          time: I18n.l('time.formats.tiny', assignment.submittedAt)
        tooltip += "<br/>Submitted: #{submittedAtString}"
      if assignment.muted
        tooltip += "<br/>Score: (muted)"
      else if assignment.studentScore?
        tooltip += "<br/>Score: #{assignment.studentScore}"
      tooltip
