define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/ScaleByBins'
  'analytics/compiled/graphs/YAxis'
  'i18n!finishing_assignments'
  'str/htmlEscape'
], (_, Base, Cover, ScaleByBins, YAxis, I18n, htmlEscape) ->

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

      assignments = _.reject(assignments.assignments, (a) -> a.non_digital_submission)
      @scaleByBins assignments.length, false
      @drawXLabel I18n.t "Assignments"
      _.each assignments, @graphAssignment

      @finish()

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, i) =>
      x = @binX i
      if (breakdown = assignment.tardinessBreakdown)?
        base = 0
        base = @drawLayer x, base, breakdown.onTime, @onTimeColor, 0, 15
        base = @drawLayer x, base, breakdown.late, @lateColor, 0, 0
        base = @drawLayer x, base, breakdown.missing, @missingColor, 15, 0

      @cover x, assignment

    ##
    # Draws the next layer at x, starting at base% and increasing by delta% in
    # color.
    drawLayer: (x, base, delta, color, top_radius, bottom_radius) ->
      if delta > 0
        summit = base + delta
        bottom = @valueY base
        top = @valueY summit
        height = bottom - top
        box = @roundedRect(x - @barWidth / 2, top, @barWidth, height, top_radius, bottom_radius)
        box.attr stroke: "white", fill: color, 'stroke-width': 2
        summit
      else
        base

    ##
    # Draw a rectangle with independent top/bottom rounding radii
    roundedRect: (x, y, w, h, tr, br) ->
      # clip radius to fit within bar
      sm = Math.min w, h
      tr = Math.min tr, sm / 2
      br = Math.min br, sm / 2
      # draw bar
      path = ["M", x + tr, y]
      path.push 'l', w - tr * 2, 0 # top
      path.push 'q', tr, 0, tr, tr # tr
      path.push 'l', 0, h - tr - br # r
      path.push 'q', 0, br, -br, br # br
      path.push 'l', -(w - br * 2), 0 # b
      path.push 'q', -br, 0, -br, -br # bl
      path.push 'l', 0, -(h - br - tr) # l
      path.push 'q', 0, -tr, tr, -tr # tl
      path.push 'z'
      @paper.path path

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
      tooltip = htmlEscape(assignment.title)
      if assignment.multipleDueDates
        tooltip += "<br/>" + htmlEscape I18n.t("Due: Multiple Dates")
      else if assignment.dueAt?
        tooltip += "<br/>" + htmlEscape I18n.t("Due: %{date}", date: I18n.l('date.formats.medium', assignment.dueAt))
      if (breakdown = assignment.tardinessBreakdown)?
        tooltip += "<br/>" + htmlEscape I18n.t("Missing: %{percent}", percent: @percentText breakdown.missing) if breakdown.missing > 0
        tooltip += "<br/>" + htmlEscape I18n.t("Late: %{percent}", percent: @percentText breakdown.late) if breakdown.late > 0
        tooltip += "<br/>" + htmlEscape I18n.t("On Time: %{percent}", percent: @percentText breakdown.onTime) if breakdown.onTime > 0
      $.raw tooltip

    percentText: (percent) ->
      String(Math.round(percent * 1000) / 10) + '%'
