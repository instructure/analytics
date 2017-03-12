define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/ScaleByBins'
  'analytics/compiled/graphs/YAxis'
  'i18n!page_views'
  'str/htmlEscape'
], (_, Base, Cover, ScaleByBins, YAxis, I18n, htmlEscape) ->

  ##
  # CategorizedPageViews visualizes the student's activity within the course by
  # type of action rather than date. Each bar represents one category. The
  # height of the bar is the number of course pages viewed in that time span.

  defaultOptions =

    ##
    # The fill color of the bars.
    barColor: "lightblue"

    ##
    # The stroke color of the bars.
    strokeColor: "#b1c6d8"

    ##
    # The size of the tick marks, in pixels.
    tickSize: 5
    
    ##
    # What to sort by ("views", "category")
    sortBy: "category"

  class CategorizedPageViews extends Base
    ##
    # Takes an element and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

      # mixin ScaleByBins functionality
      _.extend this, ScaleByBins

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # base of bars = @topmargin + @height - @bottompadding
      @base = @topMargin + @height - @bottomPadding

    ##
    # Graph the data.
    graph: (participation) ->
      return unless super

      # reduce the bins to the appropriate time scale
      bins = participation.categoryBins
      if @sortBy == 'views' && bins.length > 0
        maxViews = _.max(bins, (b) -> b.views).views
        bins = _.sortBy(bins, (b) -> [maxViews - b.views, b.category])

      @scaleToData bins
      @drawXAxis bins
      @yAxis.draw()
      _.each bins, @graphBin
      @finish()

    ##
    # Choose appropriate sizes for the graph elements based on maximum value
    # being graphed.
    scaleToData: (bins) ->
      # scale the x-axis for the number of bins
      @scaleByBins bins.length, false

      # top of max bar = @topMargin + @topPadding
      views = (bin.views for bin in bins)
      max = Math.max(views...)
      max = 1 unless max? && max > 0
      @countSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max], title: I18n.t "Page Views"

    ##
    # Draw a guide along the x-axis. Each category bin gets a pair of ticks;
    # one from the top of the frame, the other from the bottom. Each tick is
    # labeled with the bin category.
    drawXAxis: (bins) ->
      for i, bin of bins
        x = @binX i
        y = @topMargin + @height + (i % 2) * 10
        @labelBin x, y, bin.category

    ##
    # Draw label text at (x, y).
    labelBin: (x, y, text) ->
      label = @paper.text x, y, text
      label.attr fill: @frameColor

    ##
    # Graph a single bin. Fat arrowed because it's called by _.each
    graphBin: (bin, i) =>
      x = @binX i
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
        region: @paper.rect x - @coverWidth / 2, @topMargin, @coverWidth, @height
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
      $.raw "#{htmlEscape(bin.category)}<br/>#{htmlEscape I18n.t {one: "1 page view", other: "%{count} page views"}, {count: count}}"
