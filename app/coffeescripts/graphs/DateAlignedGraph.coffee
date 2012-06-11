define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/DayBinner'
  'analytics/compiled/graphs/WeekBinner'
  'analytics/compiled/graphs/MonthBinner'
  'analytics/compiled/graphs/ScaleByBins'
], (_, Base, DayBinner, WeekBinner, MonthBinner, ScaleByBins) ->

  ##
  # Parent class for all graphs that have a date-aligned x-axis. Note: Left
  # padding for this graph style is space from the frame to the start date's
  # tick mark, not the leading graph element's edge. Similarly, right padding
  # is space from the frame to the end date's tick, not the trailing graph
  # element's edge. This is necessary to keep the date graphs aligned.
  defaultOptions =

    ##
    # The date for the left end of the graph. Required.
    startDate: null

    ##
    # The date for the right end of the graph. Required.
    endDate: null

    ##
    # The size of the date tick marks, in pixels.
    tickSize: 5

  class DateAlignedGraph extends Base
    ##
    # Takes an element and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

      # mixin ScaleByBins functionality
      _.extend this, ScaleByBins

      # check for required options
      throw new Error "startDate is required" unless options.startDate?
      throw new Error "endDate is required" unless options.endDate?

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      interior = @width - @leftPadding - @rightPadding

      # mixin for the appropriate bin size
      @binner = new DayBinner(@startDate, @endDate)
      @binner = new WeekBinner(@startDate, @endDate) if @binner.count() * 5 > interior
      @binner = new MonthBinner(@startDate, @endDate) if @binner.count() * 5 > interior

      # scale the x-axis for the number of bins
      @scaleByBins @binner.count()

    ##
    # Reset the graph chrome. Adds an x-axis with daily ticks and weekly (on
    # Mondays) labels.
    reset: ->
      super
      @drawDateAxis()

    ##
    # Convert a date to a bin index.
    dateBin: (date) ->
      @binner.bin date

    ##
    # Convert a date to its bin's x-coordinate.
    binnedDateX: (date) ->
      @binX @dateBin date

    ##
    # Convert a date to an intra-bin x-coordinate.
    dateX: (datetime) ->
      floorDate = @binner.reduce datetime
      ceilDate = @binner.nextTick floorDate
      floorX = @binnedDateX floorDate
      if floorDate.equals datetime
        floorX
      else
        ceilX = @binnedDateX ceilDate
        fraction = (datetime.getTime() - floorDate.getTime()) / (ceilDate.getTime() - floorDate.getTime())
        floorX + fraction * (ceilX - floorX)

    ##
    # Draw a guide along the x-axis. Each day gets a pair of ticks; one from
    # the top of the frame, the other from the bottom. The ticks are replaced
    # by a full vertical grid line on Mondays, accompanied by a label.
    drawDateAxis: ->
      # skip if we haven't set start/end dates yet (@reset will be called by
      # Base's constructor before we set startDate or endDate)
      return unless @startDate? && @endDate?
      @binner.eachTick (tick, chrome) =>
        x = @binnedDateX tick
        @drawDayTick x
        @drawWeekLine x if chrome.grid
        @dateLabel x, @topMargin + @height + 10, chrome.bottomLabel if chrome.bottomLabel
        @dateLabel x, @topMargin - 10, chrome.topLabel if chrome.topLabel

    ##
    # Draw the tick marks for a day at x.
    drawDayTick: (x) ->
      ticks = @paper.path [
        "M", x, @topMargin,
        "l", 0, @tickSize,
        "M", x, @topMargin + @height,
        "l", 0, -@tickSize ]
      ticks.attr stroke: @frameColor

    ##
    # Draw the grid line for a week at x.
    drawWeekLine: (x) ->
      gridLine = @paper.path [
        "M", x, @topMargin,
        "l", 0, @height ]
      gridLine.attr stroke: @gridColor ? @frameColor

    ##
    # Draw label text at (x, y).
    dateLabel: (x, y, text) ->
      label = @paper.text x, y, text
      label.attr fill: @frameColor
