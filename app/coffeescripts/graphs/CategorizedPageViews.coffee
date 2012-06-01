define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/YAxis'
  'i18nObj'
], (_, Base, Cover, YAxis, I18n) ->

  ##
  # CategorizedPageViews visualizes the student's activity within the course by
  # type of action rather than date. Each bar represents one category. The
  # height of the bar is the number of course pages viewed in that time span.

  defaultOptions =

    ##
    # The size of the vertical gutter between elements as a percent of the
    # width of those elements.
    gutterPercent: 0.20

    ##
    # The fill color of the bars.
    barColor: "lightblue"

    ##
    # The stroke color of the bars.
    strokeColor: "#b1c6d8"

    ##
    # The size of the tick marks, in pixels.
    tickSize: 5

  class CategorizedPageViews extends Base
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

    ##
    # Graph the data.
    graph: (participation) ->
      return unless super

      # reduce the bins to the appropriate time scale
      bins = participation.categoryBins
      @scaleToData bins
      @drawXAxis bins
      @yAxis.draw()
      _.each bins, @graphBin

    ##
    # Choose appropriate sizes for the graph elements based on maximum value
    # being graphed.
    scaleToData: (bins) ->
      # x-scaled by number of bins
      @barSpacing = (@width - @leftPadding - @rightPadding) / bins.length
      @barWidth = @barSpacing / (1 + @gutterPercent)

      # top of max bar = @topMargin + @topPadding
      views = (bin.views for bin in bins)
      max = Math.max(views...)
      max = 1 unless max? && max > 0
      @countSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max]

    ##
    # Draw a guide along the x-axis. Each category bin gets a pair of ticks;
    # one from the top of the frame, the other from the bottom. Each tick is
    # labeled with the bin category.
    drawXAxis: (bins) ->
      for i, bin of bins
        x = @x0 + @barSpacing / 2 + i * @barSpacing
        y = @topMargin + @height + 10 + (i % 2) * 10
        @drawTicks x
        @labelBin x, y, bin.category

    ##
    # Draw the tick marks for a bin at x.
    drawTicks: (x) ->
      ticks = @paper.path [
        "M", x, @topMargin,
        "l", 0, @tickSize,
        "M", x, @topMargin + @height,
        "l", 0, -@tickSize ]
      ticks.attr stroke: @frameColor

    ##
    # Draw label text at (x, y).
    labelBin: (x, y, text) ->
      label = @paper.text x, y, text
      label.attr fill: @frameColor

    ##
    # Graph a single bin. Fat arrowed because it's called by _.each
    graphBin: (bin, i) =>
      x = @x0 + (i + 0.5) * @barSpacing
      y = @valueY bin.views
      bar = @paper.rect x - @barWidth / 2, y, @barWidth, @base - y
      bar.attr stroke: @strokeColor, fill: @barColor
      @cover x, bin

    ##
    # Calculate the y-coordinate, in pixels, for a value.
    valueY: (value) =>
      @base - value * @countSpacing

    ##
    # Create a tooltip for the bin.
    cover: (x, bin) ->
      new Cover this,
        region: @paper.rect x - @barSpacing / 2, @topMargin, @barSpacing, @height
        classes: bin.category
        tooltip:
          contents: @tooltip bin
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the bin's tooltip.
    tooltip: (bin) ->
      count = bin.views
      noun = if count is 1 then "page view" else "page views"
      "#{bin.category}<br/>#{count} #{noun}"
