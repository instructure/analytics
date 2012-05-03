define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
], (_, Base, Cover) ->

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
    # The size of the vertical gutter between elements as a percent of the
    # width of those elements.
    gutterPercent: 0.20

    ##
    # The minimum spacing, in pixels, between grid lines.
    minGridSpacing: 10

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

  class Grades extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

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
      @drawGrid assignments if @gridColor
      _.each assignments, @graphAssignment

    ##
    # Choose appropriate sizes for the graph elements based on number of
    # assignments and maximum score being graphed.
    scaleToAssignments: (assignments) ->
      # left-edge of start bar = @leftMargin + @leftPadding
      # right-edge of end bar = @leftMargin + @width - @rightPadding
      # space between bars = @gutterPercent of @barWidth
      n = assignments.length
      @barWidth = (@width - @leftPadding - @rightPadding) / (n + (n - 1) * @gutterPercent)
      @barSpacing = (1 + @gutterPercent) * @barWidth
      @x0 = @leftMargin + @leftPadding + @barWidth / 2

      # top of max bar = @topMargin + @topPadding
      # base of bars = @topMargin + @height - @bottomPadding
      distributions = (assignment.scoreDistribution for assignment in assignments)
      maxScores = ((if distribution then distribution.maxScore else 0) for distribution in distributions)
      max = Math.max(1, maxScores...)
      @pointSpacing = (@height - @topPadding - @bottomPadding) / max
      @gridPoints = @calculateGridPoints @minGridSpacing
      @gridSpacing = @gridPoints * @pointSpacing

    ##
    # Calculates the number of points between grid lines such that grid lines
    # are at least minSpacing pixels apart, and the points fall in the sequence
    # [1, 5, 10, 25, 50, 100, 250, 500, 1000, ...]
    calculateGridPoints: (minSpacing) ->
      # a line every point is acceptable if the point spacing is large enough
      if @pointSpacing >= minSpacing
        return 1

      # exponent and mantissa (base 10) of the minimum number of points to
      # get above the minimum grid spacing. since minSpacing > @pointSpacing,
      # minPoints > 1 and exponent >= 0
      minPoints = minSpacing / @pointSpacing
      exponent = Math.floor(Math.log(minPoints) * Math.LOG10E)
      mantissa = minPoints / Math.pow(10, exponent)

      # if the mantissa is 1, the minPoints are a power of 10 and we can just
      # use them as is
      if mantissa == 1
        return minPoints

      # bump the (1, 2.5] range up to a (10, 25] range, but only if minPoints
      # is actually > 10
      if mantissa <= 2.5 && exponent > 0
        mantissa *= 10
        exponent -= 1

      # select the smallest of [5, 10, 25] (modulo exponent) that's greater
      # than minPoints
      return 5 * Math.pow(10, exponent) if mantissa <= 5
      return 10 * Math.pow(10, exponent) if mantissa <= 10
      return 25 * Math.pow(10, exponent)

    ##
    # Draws the grid lines.
    drawGrid: ->
      # draw a grid line at most every 10 pixels
      y = @base
      while y >= @topMargin + @topPadding
        @drawGridLine y
        y -= @gridSpacing

    ##
    # Draw a grid line at y.
    drawGridLine: (y) ->
      gridline = @paper.path ["M", @leftMargin, y, "l", @width, 0]
      gridline.attr stroke: @gridColor

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, index) =>
      x = @indexX index
      if assignment.scoreDistribution?
        @drawWhisker x, assignment
        @drawBox x, assignment
        @drawMedian x, assignment
        @drawStudentScore x, assignment if assignment.studentScore?
      else if assignment.muted
        @drawMutedAssignment x
      @cover x, assignment

    ##
    # Convert an assignment index to an x-coordinate.
    indexX: (index) ->
      @x0 + index * @barSpacing

    ##
    # Convert a score to a y-coordinate.
    scoreY: (score) ->
      @base - score * @pointSpacing

    ##
    # Draw the whisker for an assignment's score distribution
    drawWhisker: (x, assignment) ->
      whiskerTop = @scoreY assignment.scoreDistribution.maxScore
      whiskerBottom = @scoreY assignment.scoreDistribution.minScore
      whiskerHeight = whiskerBottom - whiskerTop
      whisker = @paper.rect x, whiskerTop, 1, whiskerHeight
      whisker.attr stroke: @whiskerColor, fill: "none"

    ##
    # Draw the box for an assignment's score distribution
    drawBox: (x, assignment) ->
      boxTop = @scoreY assignment.scoreDistribution.thirdQuartile
      boxBottom = @scoreY assignment.scoreDistribution.firstQuartile
      boxHeight = boxBottom - boxTop
      box = @paper.rect x - @barWidth / 2, boxTop, @barWidth, boxHeight
      box.attr stroke: @boxColor, fill: @boxColor

    ##
    # Draw the median of an assignment's score distribution
    drawMedian: (x, assignment) ->
      medianY = @scoreY assignment.scoreDistribution.median
      median = @paper.rect x - @barWidth / 2, medianY, @barWidth, 1
      median.attr stroke: @medianColor, fill: "none"

    ##
    # Draw the dot for the student's score in an assignment
    drawStudentScore: (x, assignment) ->
      scoreY = @scoreY assignment.studentScore
      colors = @valueColors assignment
      ring = @paper.circle x, scoreY, @barWidth / 4
      ring.attr stroke: colors.ring, fill: colors.ring
      center = @paper.circle x, scoreY, @barWidth / 12
      center.attr stroke: colors.center, fill: colors.center

    ##
    # Returns colors to use for the value dot of an assignment. If this is
    # being called, it's implied there is a distribution and a student score
    # for the assignment.
    valueColors: (assignment) ->
      if assignment.studentScore >= assignment.scoreDistribution.thirdQuartile
        ring: @goodRingColor
        center: @goodCenterColor
      else if assignment.studentScore >= assignment.scoreDistribution.firstQuartile
        ring: @fairRingColor
        center: @fairCenterColor
      else
        ring: @poorRingColor
        center: @poorCenterColor

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
        region: @paper.rect x - @barSpacing / 2, @topMargin, @barSpacing, @height
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
      if assignment.scoreDistribution?
        tooltip += "<br/>High: #{assignment.scoreDistribution.maxScore}"
        tooltip += "<br/>Median: #{assignment.scoreDistribution.median}"
        tooltip += "<br/>Low: #{assignment.scoreDistribution.minScore}"
        if assignment.studentScore? && assignment.pointsPossible?
          score = "#{assignment.studentScore} / #{assignment.pointsPossible}"
          tooltip += "<br/>Score: #{score}"
        else if assignment.studentScore?
          tooltip += "<br/>Score: #{assignment.studentScore}"
        else if assignment.pointsPossible?
          tooltip += "<br/>Possible: #{assignment.pointsPossible}"

      else if assignment.muted
        tooltip += "<br/>(muted)"

      tooltip
