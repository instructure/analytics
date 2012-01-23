define [
  'i18n!analytics'
  'jquery'
  'vendor/underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/helpers'
], (I18n, $, _, Base, Cover, helpers) ->

  ##
  # AssignmentTardiness visualizes the student's ability to turn in assignments
  # on time. It displays one assignment per row, with the x-axis aligned to
  # time. An assignment is displayed in its row with a diamond on the due date
  # (or at the end of the row if there is no due date) and a bar representing
  # the time between the student's submission and the due date.

  defaultOptions =

    ##
    # The date for the left end of the graph. Required.
    startDate: null

    ##
    # The date for the right end of the graph. Required.
    endDate: null

    ##
    # Padding, in pixels, between the frame and the graph contents.
    padding: 5

    ##
    # Padding, in pixels, between the top and bottom of the frame and the graph
    # contents. Can be overridden for particular sides via the options below.
    # Defaults to padding if unset.
    verticalPadding: null

    ##
    # Padding, in pixels, between the top of the frame and the graph contents.
    # Defaults to verticalPadding if unset.
    topPadding: null

    ##
    # Padding, in pixels, between the bottom of the frame and the graph
    # contents. Defaults to verticalPadding if unset.
    bottomPadding: null

    ##
    # Padding, in pixels, between the left and right of the frame and the graph
    # contents. Can be overridden for particular sides via the options below.
    # Defaults to padding if unset.
    horizontalPadding: null

    ##
    # Padding, in pixels, between the left of the frame and the graph contents.
    # Defaults to horizontalPadding if unset.
    leftPadding: null

    ##
    # Padding, in pixels, between the right of the frame and the graph
    # contents. Defaults to horizontalPadding if unset.
    rightPadding: null

    ##
    # The size of the vertical gutter between elements as a percent of the
    # height of those elements.
    gutterPercent: 0.20

    ##
    # The height of the due date diamonds, in pixels. Defaults to barHeight + 2
    # if unset.
    diamondHeight: null

    ##
    # The color to stroke the due date diamonds.
    diamondStroke: "black"

    ##
    # The height of the submission bars, in pixels.
    barHeight: 6

    ##
    # A function that returns a color for a given assignment.
    barColor: (assignment) ->
      if !assignment.submittedAt?
        # not turned in
        null
      else if !assignment.dueAt?
        # no due date, turned in
        "lightgray"
      else if assignment.onTime is true
        # has due date, turned in on time
        "green"
      else
        # has due date, turned in late
        "red"

  class AssignmentTardiness extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (divId, options) ->
      super

      # check for required options
      throw new Error "startDate is required" unless options.startDate?
      throw new Error "endDate is required" unless options.endDate?

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # these options have defaults based on other options
      @verticalPadding ?= @padding
      @topPadding ?= @verticalPadding
      @bottomPadding ?= @verticalPadding
      @horizontalPadding ?= @padding
      @leftPadding ?= @horizontalPadding
      @rightPadding ?= @horizontalPadding
      @diamondHeight ?= @barHeight + 2

      # calculate remaining pieces
      @startHour = @hour @startDate
      @endHour = @hour @endDate
      @barSpacing = (1 + @gutterPercent) * @diamondHeight

      # center of start diamond = @leftMargin + @leftPadding
      # center of end diamond = @leftMargin + @width - @rightPadding
      @x0 = @leftMargin + @leftPadding
      @hourSpacing = (@width - @leftPadding - @rightPadding) / (@endHour - @startHour)

      # middle of first bar
      @y0 = @topMargin + @topPadding + @diamondHeight / 2

    ##
    # Convert a Date object to an hour index.
    hour: (date) ->
      if date?
        helpers.dateToHours(date)
      else
        null

    ##
    # Graph the assignments.
    graph: (assignments) =>
      assignments = assignments.assignments
      if !assignments? || assignments.length == 0
        # no data
        return

      @scaleToAssignments assignments
      _.each assignments, @graphAssignment

    ##
    # Resize the graph vertically to accomodate the number of assigments.
    scaleToAssignments: (assignments) ->
      @resize height:
        @topPadding + (assignments.length - 1) * @barSpacing + @diamondHeight + @bottomPadding

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, index) =>
      dueX = @dueX assignment
      submittedX = @submittedX assignment
      y = @indexY index
      color = @barColor assignment
      if submittedX? && submittedX != dueX
        @drawSubmittedBar dueX, submittedX, y, color
      @drawDiamond dueX, y, color
      @cover dueX, y, assignment

    ##
    # Convert an assignment's due date to an x-coordinate. If no due date, use
    # submitted at. If no due date and not submitted, use the end date.
    dueX: (assignment) ->
      @hourX @hour(assignment.dueAt ? assignment.submittedAt) || @endHour

    ##
    # Convert an assignment's submitted at to an x-coordinate.
    submittedX: (assignment) ->
      submittedHour = @hour assignment.submittedAt
      if submittedHour? then @hourX submittedHour else null

    ##
    # Convert an hour index to an x-coordinate.
    hourX: (hour) ->
      @x0 + (hour - @startHour) * @hourSpacing

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
    drawDiamond: (x, y, color) ->
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
      diamond.attr stroke: @diamondStroke, fill: color

    ##
    # Create a tooltip for the assignment.
    cover: (x, y, assignment) ->
      new Cover this,
        region: @paper.rect @leftMargin, y - @barSpacing / 2, @width, @barSpacing
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
        tooltip += "<br/>#{I18n.beforeLabel 'due', "Due"} #{assignment.dueAt.toDateString()}"
      else
        tooltip += "<br/>#{I18n.t 'no_due_date', "(no due date)"}"
      if assignment.submittedAt?
        tooltip += "<br/>#{I18n.beforeLabel 'submitted', "Submitted"} #{assignment.submittedAt.toDateString()}"
      if !assignment.scoreDistribution?
        tooltip += "<br/>#{I18n.beforeLabel 'score', "Score"} #{I18n.t 'score_muted', "(muted)"}"
      else if assignment.userScore?
        tooltip += "<br/>#{I18n.beforeLabel 'score', "Score"} #{assignment.userScore}"
      tooltip
