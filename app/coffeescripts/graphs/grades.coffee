define [
  'I18n!analytics'
  'vendor/underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
], (I18n, _, Base, Cover) ->

  ##
  # Grades visualizes the student's scores on assignments compared to the
  # distribution of scores in the class. The distribution of each assignment is
  # displayed as a "bar and whiskers" plot where the top whisker reaches to the
  # max score, the bottom whisker to the min score, the box covers the first
  # through third quartiles, and the median is stroked through the box. The
  # user's score is superimposed on this as a colored dot. The distribution and
  # dot are replaced by a faint placeholder for muted assignments in student
  # view.

  defaultOptions =

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
    # width of those elements.
    gutterPercent: 0.20

    ##
    # The color to stroke the whiskers.
    whiskerStroke: "dimgray"

    ##
    # The color to stroke the borders of the boxes.
    boxStroke: "dimgray"

    ##
    # The fill color of the boxes.
    boxFill: "lightgray"

    ##
    # The color to stroke the median line.
    medianStroke: "dimgray"

    ##
    # The color to stroke the border of the value dot.
    valueStroke: "dimgray"

    ##
    # A function that returns the fill color for the value dot of a given
    # assignment. If this is being called, it's implied there is a distribution
    # and a user score for the assignment.
    valueFill: (assignment) ->
      if assignment.userScore >= assignment.scoreDistribution.thirdQuartile
        "green"
      else if assignment.userScore >= assignment.scoreDistribution.firstQuartile
        "yellow"
      else
        "red"

  class Grades extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (divId, options) ->
      super divId, options

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

      # calculate remaining pieces
      @base = @topMargin + @height - @bottomPadding

    ##
    # Graph the assignments.
    graph: (assignments) ->
      assignments = assignments.assignments
      @scaleToAssignments assignments
      _.each assignments, @graphAssignment

    ##
    # Choose appropriate sizes for the graph elements based on number of
    # assignments and maximum score being graphed.
    scaleToAssignments: (assignments) ->
      # left-edge of start bar = @leftMargin + leftPadding
      # right-edge of end bar = @leftMargin + @width - rightPadding
      # space between bars = gutterPercent of barWidth
      n = assignments.length
      @barWidth = (@width - @leftPadding - @rightPadding) / (n + (n - 1) * @gutterPercent)
      @barSpacing = (1 + @gutterPercent) * @barWidth
      @x0 = @leftMargin + @leftPadding + @barWidth / 2

      # top of max bar = @topMargin + topPadding
      # base of bars = @topMargin + @height - bottomPadding
      distributions = (assignment.scoreDistribution for assignment in assignments)
      maxScores = ((if distribution then distribution.maxScore else 0) for distribution in distributions)
      max = Math.max(0, maxScores...)
      @pointSpacing = (@height - @topPadding - @bottomPadding) / max

    ##
    # Graph a single assignment. Fat arrowed because it's called by _.each
    graphAssignment: (assignment, index) =>
      x = @indexX index
      if assignment.scoreDistribution?
        @drawWhisker x, assignment
        @drawBox x, assignment
        @drawMedian x, assignment
        @drawUserScore x, assignment if assignment.userScore?
      else
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
      whisker.attr stroke: @whiskerStroke, fill: "none"

    ##
    # Draw the box for an assignment's score distribution
    drawBox: (x, assignment) ->
      boxTop = @scoreY assignment.scoreDistribution.thirdQuartile
      boxBottom = @scoreY assignment.scoreDistribution.firstQuartile
      boxHeight = boxBottom - boxTop
      box = @paper.rect x - @barWidth / 2, boxTop, @barWidth, boxHeight
      box.attr stroke: @boxStroke, fill: @boxFill

    ##
    # Draw the median of an assignment's score distribution
    drawMedian: (x, assignment) ->
      medianY = @scoreY assignment.scoreDistribution.median
      median = @paper.rect x - @barWidth / 2, medianY, @barWidth, 1
      median.attr stroke: @medianStroke, fill: "none"

    ##
    # Draw the dot for the user's score in an assignment
    drawUserScore: (x, assignment) ->
      scoreY = @scoreY assignment.userScore
      score = @paper.circle x, scoreY, @barWidth / 4
      score.attr stroke: @valueStroke, fill: @valueFill assignment

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
        tooltip += "<br/>#{I18n.beforeLabel 'high', "High"} #{assignment.scoreDistribution.maxScore}"
        tooltip += "<br/>#{I18n.beforeLabel 'median', "Median"} #{assignment.scoreDistribution.median}"
        tooltip += "<br/>#{I18n.beforeLabel 'low', "Low"} #{assignment.scoreDistribution.minScore}"
        if assignment.userScore?
          tooltip += "<br/>#{I18n.beforeLabel 'score', "Score"} #{assignment.userScore}"
      else
        tooltip += "<br/>#{I18n.t 'score_muted', '(muted)'}"
      tooltip
