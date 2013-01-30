define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/ScaleByBins'
  'analytics/compiled/graphs/YAxis'
  'i18nObj'
], (_, Base, Cover, ScaleByBins, YAxis, I18n) ->

  ##
  # FinishingAssignmentCourse visualizes the proportion of students that are
  # turning in assignments on time, late, or not at all. Each assignment gets
  # one bar, which is shown as layered percentiles. The layers are, from bottom
  # to top:
  #
  #   * Percent of students that turned the assignment in on time.
  #   * Percent of students that turned the assignment in late (if past due).
  #   * Percent of students that missed the assignment (if past due).
  #
  # For assignments that are past due, these three layers will add up to 100%.
  # For assignments that are not yet due or which have no due date, only the
  # first layer will be included and can be read as the percentage of students
  # that have completed the assignment.

  defaultOptions =

    ##
    # The color of the bottom layer (on time).
    onTimeColor: "darkgreen"

    ##
    # The color of the middle layer (past due, turned in late).
    lateColor: "darkyellow"

    ##
    # The color of the top layer (past due, missing).
    missingColor: "red"

  class Grades extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

      # mixin ScaleByBins functionality
      _.extend this, ScaleByBins

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      @base = @topMargin + @height - @bottomPadding

      # top of max bar = @topMargin + @topPadding
      # base of bars = @topMargin + @height - @bottomPadding
      # grid lines every 10%
      @innerHeight = (@height - @topPadding - @bottomPadding)
      @yAxis = new YAxis this, range: [0, 1], style: 'percent'

    reset: ->
      super
      @yAxis?.draw()

    ##
    # Graph the assignments.
    graph: (assignments) ->
      return unless super

      assignments = assignments.assignments
      @scaleByBins assignments.length
      @drawXLabel "Assignments"
      _.each assignments, @graphAssignment

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, i) =>
      x = @binX i
      if (breakdown = assignment.tardinessBreakdown)?
        base = 0
        base = @drawLayer x, base, breakdown.onTime, @onTimeColor
        base = @drawLayer x, base, breakdown.late, @lateColor
        base = @drawLayer x, base, breakdown.missing, @missingColor

      @cover x, assignment

    ##
    # Draws the next layer at x, starting at base% and increasing by delta% in
    # color.
    drawLayer: (x, base, delta, color) ->
      if delta > 0
        summit = base + delta
        bottom = @valueY base
        top = @valueY summit
        height = bottom - top
        box = @paper.rect x - @barWidth / 2, top, @barWidth, height
        box.attr stroke: "white", fill: color
        summit
      else
        base

    ##
    # Convert a score to a y-coordinate.
    valueY: (percent) ->
      @base - percent * @innerHeight

    ##
    # Create a tooltip for the assignment.
    cover: (x, assignment) ->
      new Cover this,
        region: @paper.rect x - @coverWidth / 2, @topMargin, @coverWidth, @height
        classes: "assignment_#{assignment.id}"
        tooltip:
          contents: @tooltip assignment
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the assignment's tooltip.
    tooltip: (assignment) ->
      tooltip = assignment.title
      if assignment.multipleDueDates
        tooltip += "<br/>Due: Multiple Dates"
      else if assignment.dueAt?
        tooltip += "<br/>Due: #{I18n.l 'date.formats.medium', assignment.dueAt}"
      if (breakdown = assignment.tardinessBreakdown)?
        tooltip += "<br/>Missing: #{@percentText breakdown.missing}" if breakdown.missing > 0
        tooltip += "<br/>Late: #{@percentText breakdown.late}" if breakdown.late > 0
        tooltip += "<br/>On Time: #{@percentText breakdown.onTime}" if breakdown.onTime > 0
      tooltip

    percentText: (percent) ->
      String(Math.round(percent * 1000) / 10) + '%'
