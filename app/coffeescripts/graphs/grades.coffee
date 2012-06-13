define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/YAxis'
], (_, Base, Cover, YAxis) ->

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
      @yAxis.draw()
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
      @barWidth = Math.min(@barWidth, 30)

      # top of max bar = @topMargin + @topPadding
      # base of bars = @topMargin + @height - @bottomPadding
      distributions = (assignment.scoreDistribution for assignment in assignments)
      maxScores = ((if distribution then distribution.maxScore else 0) for distribution in distributions)
      max = Math.max(maxScores...)
      max = 1 unless max? && max > 0
      @pointSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max]

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
    # being called, it's implied there is a distribution and a student score
    # for the assignment.
    valueColors: (assignment) ->
      if assignment.studentScore >= assignment.scoreDistribution.median
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
