define [
  'vendor/underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/date_axis'
  'analytics/compiled/helpers'
], (_, Base, Cover, dateAxis, helpers) ->

  ##
  # PageViews visualizes the student's activity within the course. Each bar
  # represents one day. The height of the bar is the number of course pages
  # viewed that day. The bar is blue on days in which the user "participated"
  # (took a quiz, posted a discussion reply, etc.) and gray on other days.

  defaultOptions =

    ##
    # The date for the left end of the graph. Required.
    startDate: null

    ##
    # The date for the right end of the graph. Required.
    endDate: null

    ##
    # Padding, in pixels, between the frame and the graph contents. Note: On
    # the left and right, this is space from the frame to the *center* of the
    # bar on the startDate, not the outer edge. This is necessary to keep the
    # date graphs aligned.
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
    # The fill color of the bars on days without participations.
    barColor: "lightgray"

    ##
    # The fill color of the bars on days with participations.
    participationColor: "lightblue"

  class PageViews extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (divId, options) ->
      super divId, options

      # check for required options
      throw new Error "startDate is required" unless options.startDate?
      throw new Error "endDate is required" unless options.endDate?

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
      @startDay = @day @startDate
      @endDay = @day @endDate

      # center of start bar = @leftMargin + leftPadding
      # center of end bar = @leftMargin + @width - rightPadding
      # space between bars = gutterPercent of barWidth
      @x0 = @leftMargin + @leftPadding
      @daySpacing = (@width - @leftPadding - @rightPadding) / (@endDay - @startDay)
      @barWidth = @daySpacing / (1 + @gutterPercent)

      # base of bars = @topMargin + @height - @bottomPadding
      @base = @topMargin + @height - @bottomPadding

    ##
    # Convert a Date object to a day index.
    day: (date) ->
      if date?
        helpers.dateToDays(date)
      else
        null

    ##
    # Graph the data.
    graph: (participation) ->
      histogram = @binData participation
      @scaleToData histogram
      dateAxis this
      _.each histogram, @graphBin

    ##
    # Bin the page view and participation data by day.
    binData: (participation) ->
      histogram = {}
      for date, counts of participation.pageViews
        day = @day Date.parse date
        if day >= @startDay && day <= @endDay
          histogram[day] ?= total: 0
          for action, count of counts
            histogram[day].total += count
            histogram[day].counts ?= {}
            histogram[day].counts[action] ?= 0
            histogram[day].counts[action] += count
      for event in participation.participations
        day = @day Date.parse event.created_at
        histogram[day] ?= total: 0
        histogram[day].participations ?= []
        histogram[day].participations.push event
      histogram

    ##
    # Choose appropriate sizes for the graph elements based on maximum value
    # being graphed.
    scaleToData: (histogram) ->
      # top of max bar = @topMargin + @topPadding
      totals = (bin.total for day, bin of histogram)
      max = Math.max(totals...)
      @countSpacing = (@height - @topPadding - @bottomPadding) / max

    ##
    # Graph a single bin. Fat arrowed because it's called by _.each
    graphBin: (bin, day) =>
      x = @dayX day
      height = @binHeight bin
      bar = @paper.rect x - @barWidth / 2, @base - height, @barWidth, height
      bar.attr @binColors bin
      @cover x, day, bin

    ##
    # Convert an day index to an x-coordinate.
    dayX: (day) ->
      @x0 + (day - @startDay) * @daySpacing

    ##
    # Convert a date to an x-coordinate.
    dateX: (date) ->
      @dayX @day date

    ##
    # Calculate the height of a bin, in pixels.
    binHeight: (bin) ->
      bin.total * @countSpacing

    ##
    # Determine the colors to use for a bin.
    binColors: (bin) ->
      if bin.participations?
        stroke: "white"
        fill: @participationColor
      else
        stroke: "white"
        fill: @barColor

    ##
    # Create a tooltip for the bin.
    cover: (x, day, bin) ->
      new Cover this,
        region: @paper.rect x - @daySpacing / 2, @topMargin, @daySpacing, @height
        tooltip:
          contents: @tooltip day, bin
          x: x
          y: @base
          direction: 'down'

    ##
    # Build the text for the bin's tooltip.
    tooltip: (day, bin) ->
      tooltip = helpers.dayToDate(day).toDateString()
      if bin.participations?
        count = bin.participations.length
        noun = if count is 1 then "participation" else "participations"
        tooltip += "<br/>#{count} #{noun}"
      if bin.total > 0
        count = bin.total
        noun = if count is 1 then "page view" else "page views"
        tooltip += "<br/>#{count} #{noun}"
