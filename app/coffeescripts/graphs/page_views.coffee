define [
  'underscore'
  'analytics/compiled/graphs/DateAlignedGraph'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/YAxis'
  'i18n!page_views'
  'str/htmlEscape'
], (_, DateAlignedGraph, Cover, YAxis, I18n, htmlEscape) ->

  ##
  # PageViews visualizes the student's activity within the course. Each bar
  # represents one time span (typically one day, but if there are a large
  # amount of days, it may instead by one week per bin). The height of the bar
  # is the number of course pages viewed in that time span. The bar is blue on
  # if there were any participations in that time span (took a quiz, posted a
  # discussion reply, etc.) and gray otherwise.

  defaultOptions =

    ##
    # The fill color of the bars for bins without participations.
    barColor: "lightgray"

    ##
    # The fill color of the bars for bins with participations.
    participationColor: "lightblue"

  class PageViews extends DateAlignedGraph
    ##
    # Takes an element and options, same as for DateAlignedGraph. Recognizes
    # the options described above in addition to the options for
    # DateAlignedGraph.
    constructor: (div, options) ->
      super

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # base of bars = @topMargin + @height - @bottomPadding
      @base = @topMargin + @height - @bottomPadding

    ##
    # Combine bins by an index reduction.
    reduceBins: (sourceBins) ->
      bins = []
      binMap = {}
      _.each sourceBins, (bin) =>
        if bin.date.between @startDate, @endDate
          index = @binner.reduce bin.date
          if binMap[index]
            binMap[index].views += bin.views
            binMap[index].participations += bin.participations
          else
            binMap[index] = _.extend {}, bin
            binMap[index].date = index
            bins.push binMap[index]
      bins

    ##
    # Graph the data.
    graph: (participation) ->
      return unless super

      # reduce the bins to the appropriate time scale
      bins = @reduceBins participation.bins
      @scaleToData bins
      @yAxis.draw()
      _.each bins, @graphBin

      @finish()

    ##
    # Choose appropriate sizes for the graph elements based on maximum value
    # being graphed.
    scaleToData: (bins) ->
      # top of max bar = @topMargin + @topPadding
      views = (bin.views for bin in bins)
      max = Math.max(views...)
      max = 1 unless max? && max > 0
      @countSpacing = (@height - @topPadding - @bottomPadding) / max
      @yAxis = new YAxis this, range: [0, max], title: I18n.t("Page Views")

    ##
    # Graph a single bin. Fat arrowed because it's called by _.each
    graphBin: (bin) =>
      x = @binnedDateX bin.date
      y = @valueY bin.views
      bar = @paper.rect x - @barWidth / 2, y, @barWidth, @base - y
      bar.attr @binColors bin
      @cover x, bin

    ##
    # Calculate the height of a bin, in pixels.
    valueY: (j) ->
      @base - j * @countSpacing

    ##
    # Determine the colors to use for a bin.
    binColors: (bin) ->
      if bin.participations > 0
        stroke: "white"
        fill: @participationColor
      else
        stroke: "white"
        fill: @barColor

    ##
    # Create a tooltip for the bin.
    cover: (x, bin) ->
      new Cover this,
        region: @paper.rect x - @coverWidth / 2, @topMargin, @coverWidth, @height
        classes: I18n.l 'date.formats.default', bin.date
        tooltip:
          contents: @tooltip bin
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the bin's tooltip.
    tooltip: (bin) ->
      tooltip = htmlEscape @binDateText(bin)
      if bin.participations > 0
        count = bin.participations
        tooltip += "<br/>" + htmlEscape I18n.t({one: "1 participation", other: "%{count} participations"}, {count: count})
      if bin.views > 0
        count = bin.views
        tooltip += "<br/>" + htmlEscape I18n.t({one: "1 page view", other: "%{count} page views"}, {count: count})
      $.raw tooltip
