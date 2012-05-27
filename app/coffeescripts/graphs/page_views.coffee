define [
  'underscore'
  'analytics/compiled/graphs/DateAlignedGraph'
  'analytics/compiled/graphs/cover'
  'i18nObj'
], (_, DateAlignedGraph, Cover, I18n) ->

  ##
  # PageViews visualizes the student's activity within the course. Each bar
  # represents one time span (typically one day, but if there are a large
  # amount of days, it may instead by one week per bin). The height of the bar
  # is the number of course pages viewed in that time span. The bar is blue on
  # if there were any participations in that time span (took a quiz, posted a
  # discussion reply, etc.) and gray otherwise.

  defaultOptions =

    ##
    # The size of the vertical gutter between elements as a percent of the
    # width of those elements.
    gutterPercent: 0.20

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

      # space between bars = gutterPercent of barWidth
      @barWidth = @binSpacing / (1 + @gutterPercent)

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
      _.each bins, @graphBin

    ##
    # Choose appropriate sizes for the graph elements based on maximum value
    # being graphed.
    scaleToData: (bins) ->
      # top of max bar = @topMargin + @topPadding
      totals = (bin.total for bin in bins)
      max = Math.max(totals...)
      @countSpacing = (@height - @topPadding - @bottomPadding) / max

    ##
    # Graph a single bin. Fat arrowed because it's called by _.each
    graphBin: (bin) =>
      x = @dateX bin.date
      height = @binHeight bin
      bar = @paper.rect x - @barWidth / 2, @base - height, @barWidth, height
      bar.attr @binColors bin
      @cover x, bin

    ##
    # Calculate the height of a bin, in pixels.
    binHeight: (bin) ->
      bin.total * @countSpacing

    ##
    # Determine the colors to use for a bin.
    binColors: (bin) ->
      if bin.participations.length > 0
        stroke: "white"
        fill: @participationColor
      else
        stroke: "white"
        fill: @barColor

    ##
    # Create a tooltip for the bin.
    cover: (x, bin) ->
      new Cover this,
        region: @paper.rect x - @binSpacing / 2, @topMargin, @binSpacing, @height
        classes: I18n.l 'date.formats.default', bin.date
        tooltip:
          contents: @tooltip bin
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the bin's tooltip.
    tooltip: (bin) ->
      tooltip = I18n.l 'date.formats.medium', bin.date
      if bin.participations.length > 0
        count = bin.participations.length
        noun = if count is 1 then "participation" else "participations"
        tooltip += "<br/>#{count} #{noun}"
      if bin.total > 0
        count = bin.total
        noun = if count is 1 then "page view" else "page views"
        tooltip += "<br/>#{count} #{noun}"
