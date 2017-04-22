define [
  'underscore'
  'analytics/compiled/graphs/DateAlignedGraph'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/helpers'
  'i18n!time'
  'str/htmlEscape'
], (_, DateAlignedGraph, Cover, helpers, I18n, htmlEscape) ->

  ##
  # AssignmentTardiness visualizes the student's ability to turn in assignments
  # on time. It displays one assignment per row, with the x-axis aligned to
  # time. An assignment is displayed in its row with a diamond on the due date
  # (or at the end of the row if there is no due date) and a bar representing
  # the time between the student's submission and the due date.

  defaultOptions =

    ##
    # The height of the assignment lanes, in pixels
    laneHeight: 16

    ##
    # The height of the submission bars, in pixels.
    barHeight: 4

    ##
    # The height of the due date diamonds, in pixels. Defaults to laneHeight
    # if unset.
    shapeHeight: null

    ##
    # The size of the vertical gutter between elements as a percent of the
    # height of those elements.
    gutterPercent: 0.25

    ##
    # Color for on time assignments.
    colorOnTime: "green"

    ##
    # Color for late assignments.
    colorLate: "gold"

    ##
    # Color for missing assignments.
    colorMissing: "red"

    ##
    # Color for undated assignments.
    colorUndated: "darkgray"

    ##
    # Color for unfilled shapes
    colorEmpty: "white"

    ##
    # Message when dates fall outside bounds of graph
    clippedWarningLabel: I18n.t "Note: some items fall outside the start and/or end dates of the course"

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

      @shapeHeight ?= @laneHeight
      @gutterHeight = @gutterPercent * @laneHeight
      @barSpacing = @laneHeight + @gutterHeight

      # middle of first bar
      @y0 = @topMargin + @topPadding + @shapeHeight / 2

    ##
    # Graph the assignments.
    graph: (assignments) =>
      return unless super

      assignments = _.reject(assignments.assignments, (a) -> a.non_digital_submission)
      if assignments? && assignments.length > 0
        @scaleToAssignments assignments
        @drawGrid assignments if @gridColor
        @drawYLabel I18n.t "Assignments"
        _.each assignments, @graphAssignment

        if @clippedDate
          label = @clippedWarningLabel
          @drawWarning label

      @finish()

    ##
    # Resize the graph vertically to accomodate the number of assigments.
    scaleToAssignments: (assignments) ->
      @resize height:
        @topPadding + (assignments.length - 1) * @barSpacing + @shapeHeight + @laneHeight / 2 + @bottomPadding

    ##
    # Draws the gutters between the assignments.
    drawGrid: (assignments) ->
      for i in [0..assignments.length - 1]
        @drawGridLine @gridY i

    drawGridLine: (y) ->
      gridline = @paper.path ["M", @leftMargin, y, "l", @width, 0]
      gridline.attr stroke: @gridColor

    gridY: (index) ->
      (@indexY index)

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, index) =>
      dueX = @dueX assignment
      submittedX = @submittedX assignment
      y = @indexY index
      attrs = @shape_attrs assignment
      if submittedX? && submittedX != dueX
        @drawSubmittedBar dueX, submittedX, y, attrs.color
      @drawShape dueX, y, @shapeHeight / 2, attrs
      @cover dueX, y, assignment

    ##
    # Determine the colors to use for an assignment.
    shape_attrs: (assignment) ->
      if !assignment.dueAt?
        # no due date
        if assignment.submittedAt?
          # if it's submitted, it's "on time"
          color: @colorOnTime
          shape: 'circle'
          fill: @colorOnTime
        else
          # otherwise it's "future"
          color: @colorUndated
          shape: 'circle'
          fill: @colorEmpty
      else if assignment.onTime is true
        # has due date, turned in on time
        color: @colorOnTime
        shape: 'circle'
        fill: @colorOnTime
      else if assignment.onTime is false
        # has due date, turned in late
        color: @colorLate
        shape: 'triangle'
        fill: @colorLate
      else if assignment.dueAt > new Date
        # due in the future, not turned in
        color: @colorUndated
        shape: 'circle'
        fill: @colorEmpty
      else
        # due in the past, not turned in
        color: @colorMissing
        shape: 'square'
        fill: @colorMissing

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
    # Create a tooltip for the assignment.
    cover: (x, y, assignment) ->
      new Cover this,
        region: @paper.rect @leftMargin, y - @barSpacing / 2, @width, @barSpacing
        classes: "assignment_#{assignment.id}"
        tooltip:
          contents: @tooltip assignment
          x: x
          y: y + @shapeHeight / 2
          direction: 'down'

    ##
    # Build the text for the assignment's tooltip.
    tooltip: (assignment) ->
      tooltip = htmlEscape(assignment.title)

      if assignment.dueAt?
        dueAtString = I18n.t 'due_date', "%{date} by %{time}",
          date: I18n.l('date.formats.medium', assignment.dueAt)
          time: I18n.l('time.formats.tiny', assignment.dueAt)
        tooltip += "<br/>" + htmlEscape I18n.t("Due: %{dateTime}", dateTime: dueAtString)
      else
        tooltip += "<br/>" + htmlEscape I18n.t("(no due date)")
      if assignment.submittedAt?
        submittedAtString = I18n.t 'event', "%{date} at %{time}",
          date: I18n.l('date.formats.medium', assignment.submittedAt)
          time: I18n.l('time.formats.tiny', assignment.submittedAt)
        tooltip += "<br/>" + htmlEscape I18n.t("Submitted: %{dateTime}", dateTime: submittedAtString)
      if assignment.muted
        tooltip += "<br/>" + htmlEscape I18n.t("Score: (muted)")
      else if assignment.studentScore?
        tooltip += "<br/>" + htmlEscape I18n.t("Score: %{score}", score: I18n.n assignment.studentScore)
      $.raw tooltip
