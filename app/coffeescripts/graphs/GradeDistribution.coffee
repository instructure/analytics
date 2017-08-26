define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/YAxis'
  'i18n!grade_distribution'
], (_, Base, Cover, YAxis, I18n) ->

  ##
  # GradeDistribution visualizes the distribution of grades across all students
  # enrollments in department courses.

  defaultOptions =

    ##
    # The color of the line graph.
    strokeColor: "#b1c6d8"

    ##
    # The fill color of the area under the line graph
    areaColor: "lightblue"

  class GradeDistribution extends Base
    ##
    # Takes an element and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # left edge of leftmost bar diamond = @leftMargin + @leftPadding
      @x0 = @leftMargin + @leftPadding

      # base of bars = @topmargin + @height - @bottompadding
      @base = @topMargin + @height - @bottomPadding

      # always graphing scores from 0 to 100
      @scoreSpacing = (@width - @leftPadding - @rightPadding) / 100

    ##
    # Add X-axis to reset.
    reset: ->
      super
      @drawXAxis()

    ##
    # Graph the data.
    graph: (distribution) ->
      return unless super

      # scale the y-axis
      max = @scaleToData distribution.values
      @yAxis.draw()

      # x label
      @drawXLabel I18n.t("Grades"), offset: @labelHeight

      # build path for distribution line
      path = _.map distribution.values, (value, score) =>
        value = Math.min value, max if score is 0
        [ (if score is 0 then 'M' else 'L'), @scoreX(score), @valueY(value) ]

      # stroke the line
      @paper.path(path).attr
        stroke: @strokeColor
        "stroke-width": 2
        "stroke-linejoin": "round"
        "stroke-linecap": "round"
        "stroke-dasharray": ""

      # extend the path to close around the area under the line
      path = path.concat [
        ["L", @scoreX(100), @valueY(0)],
        ["L", @scoreX(0), @valueY(0)],
        ["z"]]

      # fill that area
      @paper.path(path).attr
        stroke: "none"
        fill: @areaColor

      # add covers
      _.each distribution.values, (value, score) =>
        @cover score, value

      @finish()

    ##
    # Calculate the x-coordinate of a score, in pixels.
    scoreX: (score) ->
      @x0 + score * @scoreSpacing

    ##
    # Calculate the y-coordinate of a value, in pixels.
    valueY: (value) ->
      @base - value * @countSpacing

    ##
    # Choose appropriate scale for the y-dimension so as to put the tallest
    # point just at the top of the graph.
    scaleToData: (values) ->
      max = Math.max values.slice(1)...
      max = 0.001 unless max? && max > 0
      @countSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max], style: 'percent'
      max

    ##
    # Draw a guide along the x-axis. Tick and label every 5 scores.
    drawXAxis: (bins) ->
      i = 0
      while i <= 100
        x = @scoreX i
        @labelTick x, i
        i += 5

    ##
    # Draw label text at (x, y).
    labelTick: (x, text) ->
      y = @topMargin + @height
      label = @paper.text x, y, text
      label.attr fill: @frameColor
      @labelHeight = label.getBBox().height

    ##
    # Create a tooltip for a score.
    cover: (score, value) ->
      x = @scoreX score
      new Cover this,
        region: @paper.rect x - @scoreSpacing / 2, @topMargin, @scoreSpacing, @height
        tooltip:
          contents: @tooltip(score, value)
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the score tooltip.
    tooltip: (score, value) ->
      I18n.t("%{percent} of students scored %{score}", percent: @percentText(value), score: @percentText(score / 100))

    percentText: (percent) ->
      I18n.n(Math.round((percent || 0) * 1000) / 10, { percentage: true })
