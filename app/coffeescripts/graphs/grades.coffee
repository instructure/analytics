define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/ScaleByBins'
  'analytics/compiled/graphs/YAxis'
  'compiled/str/TextHelper'
  'str/htmlEscape'
  'i18n!analytics_grades'
], (_, Base, Cover, ScaleByBins, YAxis, {delimit}, htmlEscape, I18n) ->

  ##
  # Grades visualizes the student's scores on assignments compared to the
  # distribution of scores in the class. The distribution of each assignment is
  # displayed as a "bar and whiskers" plot where the top whisker reaches to the
  # max score, the bottom whisker to the min score, the box covers the first
  # through third quartiles, and the median is stroked through the box. The
  # student's score is superimposed on this as a colored dot. The distribution
  # and dot are replaced by a faint placeholder for muted assignments in
  # student view.

  defaultOptions =

    ##
    # The color of the whiskers.
    whiskerColor: "dimgray"

    ##
    # The color of the boxes.
    boxColor: "lightgray"

    ##
    # The color of the median line.
    medianColor: "dimgray"

    ##
    # The colors of the outer rings of value dots, by performance level.
    goodRingColor: "lightgreen"
    fairRingColor: "lightyellow"
    poorRingColor: "lightred"

    ##
    # The colors of the centers of value dots, by performance level.
    goodCenterColor: "darkgreen"
    fairCenterColor: "darkyellow"
    poorCenterColor: "darkred"

    ##
    # Max width of a bar, in pixels. (Overrides default from ScaleByBins)
    maxBarWidth: 30
    gutterPercent: 1.0

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

    ##
    # Graph the assignments.
    graph: (assignments) ->
      return unless super

      assignments = assignments.assignments
      @scaleToAssignments assignments
      @yAxis.draw()
      @drawXLabel I18n.t "Assignments"
      _.each assignments, @graphAssignment

    ##
    # given an assignment, what's the max score possible/achieved so far?
    maxAssignmentScore: (assignment) ->
      if assignment.pointsPossible?
        assignment.pointsPossible
      else if assignment.scoreDistribution?
        assignment.scoreDistribution.maxScore
      else
        0

    ##
    # Choose appropriate sizes for the graph elements based on number of
    # assignments and maximum score being graphed.
    scaleToAssignments: (assignments) ->
      # scale the x-axis for the number of bins
      @scaleByBins assignments.length, false

      # top of max bar = @topMargin + @topPadding
      # base of bars = @topMargin + @height - @bottomPadding
      maxScores = (@maxAssignmentScore(a) for a in assignments)

      max = Math.max(maxScores...)
      max = 1 unless max? && max > 0
      @pointSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max], title: I18n.t "Points"

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, i) =>
      x = @binX i

      if assignment.muted
        @drawMutedAssignment x
      else
        if assignment.scoreDistribution?
          @drawWhisker x, assignment
          @drawBox x, assignment
          @drawMedian x, assignment

        if assignment.studentScore?
          @drawStudentScore x, assignment

      @cover x, assignment

    ##
    # Convert a score to a y-coordinate.
    valueY: (score) ->
      @base - score * @pointSpacing

    ##
    # Draw the whisker for an assignment's score distribution
    drawWhisker: (x, assignment) ->
      whiskerTop = @valueY assignment.scoreDistribution.maxScore
      whiskerBottom = @valueY assignment.scoreDistribution.minScore
      whiskerHeight = whiskerBottom - whiskerTop
      whisker = @paper.rect x, whiskerTop, 1, whiskerHeight
      whisker.attr stroke: @whiskerColor, fill: "none"

    ##
    # Draw the box for an assignment's score distribution
    drawBox: (x, assignment) ->
      boxTop = @valueY assignment.scoreDistribution.thirdQuartile
      boxBottom = @valueY assignment.scoreDistribution.firstQuartile
      boxHeight = boxBottom - boxTop
      box = @paper.rect x - @barWidth * 0.3, boxTop, @barWidth * 0.6, boxHeight
      box.attr stroke: @boxColor, fill: @boxColor

    ##
    # Draw the median of an assignment's score distribution
    drawMedian: (x, assignment) ->
      medianY = @valueY assignment.scoreDistribution.median
      median = @paper.rect x - @barWidth / 2, medianY, @barWidth, 1
      median.attr stroke: "none", fill: @medianColor

    ##
    # Draw the dot for the student's score in an assignment
    drawStudentScore: (x, assignment) ->
      scoreY = @valueY assignment.studentScore
      colors = @valueColors assignment
      ring = @paper.circle x, scoreY, @barWidth / 4
      ring.attr stroke: colors.ring, fill: colors.ring
      center = @paper.circle x, scoreY, @barWidth / 12
      center.attr stroke: colors.center, fill: colors.center

    ##
    # Returns colors to use for the value dot of an assignment. If this is
    # being called, it's implied there is a student score for the assignment.
    valueColors: (assignment) ->
      if assignment.scoreDistribution?
        if assignment.studentScore >= assignment.scoreDistribution.median
          ring: @goodRingColor
          center: @goodCenterColor
        else if assignment.studentScore >= assignment.scoreDistribution.firstQuartile
          ring: @fairRingColor
          center: @fairCenterColor
        else
          ring: @poorRingColor
          center: @poorCenterColor
      else
        ring: @goodRingColor
        center: @goodCenterColor

    ##
    # Draw a muted assignment indicator
    drawMutedAssignment: (x) ->
      whisker = @paper.rect x, @middle - @height * 0.4, 1, @height * 0.6
      whisker.attr stroke: @gridColor, fill: "none"
      dot = @paper.circle x, @middle, @barWidth / 4
      dot.attr stroke: @gridColor, fill: @gridColor

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
      if assignment.scoreDistribution?
        tooltip += "<br/>" + htmlEscape I18n.t("High: %{score}", score: delimit assignment.scoreDistribution.maxScore)
        tooltip += "<br/>" + htmlEscape I18n.t("Median: %{score}", score: delimit assignment.scoreDistribution.median)
        tooltip += "<br/>" + htmlEscape I18n.t("Low: %{score}", score: delimit assignment.scoreDistribution.minScore)
        if assignment.studentScore? && assignment.pointsPossible?
          score = "#{delimit assignment.studentScore} / #{delimit assignment.pointsPossible}"
          tooltip += "<br/>" + htmlEscape I18n.t("Score: %{score}", score: score)
        else if assignment.studentScore?
          tooltip += "<br/>" + htmlEscape I18n.t("Score: %{score}", score: delimit assignment.studentScore)
        else if assignment.pointsPossible?
          tooltip += "<br/>" + htmlEscape I18n.t("Possible: %{score}", score: delimit assignment.pointsPossible)
      else if assignment.muted
        tooltip += "<br/>" + htmlEscape I18n.t("(muted)")
      else if assignment.studentScore? && assignment.pointsPossible?
        score = "#{delimit assignment.studentScore} / #{delimit assignment.pointsPossible}"
        tooltip += "<br/>" + htmlEscape I18n.t("Score: %{score}", score: score)

      $.raw tooltip
