define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/DayBinner'
  'analytics/compiled/graphs/WeekBinner'
  'analytics/compiled/graphs/MonthBinner'
  'analytics/compiled/graphs/ScaleByBins'
  'analytics/compiled/helpers'
  'i18n!page_views'
], (_, Base, DayBinner, WeekBinner, MonthBinner, ScaleByBins, helpers, I18n) ->

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

    ##
    # If any date is outside the bounds of the graph, we have a clipped date
    clippedDate: false


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

      @initScale()

    ##
    # Set up X-axis scale
    initScale: ->
      interior = @width - @leftPadding - @rightPadding

      # mixin for the appropriate bin size
      # use a minimum of 10 pixels for bar width plus spacing before consolidating
      @binner = new DayBinner(@startDate, @endDate)
      @binner = new WeekBinner(@startDate, @endDate) if @binner.count() * 10 > interior
      @binner = new MonthBinner(@startDate, @endDate) if @binner.count() * 10 > interior

      # scale the x-axis for the number of bins
      @scaleByBins @binner.count()

    ##
    # Reset the graph chrome. Adds an x-axis with daily ticks and weekly (on
    # Mondays) labels.
    reset: ->
      super
      @initScale() if @startDate
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
    # Given a datetime, return the floor and ceil as calculated by the binner
    dateExtent: (datetime) ->
      floor = @binner.reduce datetime
      [floor, @binner.nextTick floor]

    ##
    # Given a datetime and a datetime range, return a number from 0.0 to 1.0
    dateFraction: (datetime, floorDate, ceilDate) ->
      deltaSeconds = datetime.getTime() - floorDate.getTime()
      totalSeconds = ceilDate.getTime() - floorDate.getTime()
      deltaSeconds / totalSeconds

    ##
    # Convert a date to an intra-bin x-coordinate.
    dateX: (datetime) ->
      minX = @leftMargin
      maxX = @leftMargin + @width

      [floorDate, ceilDate] = @dateExtent(datetime) 
      floorX = @binnedDateX floorDate
      ceilX = @binnedDateX ceilDate

      fraction = @dateFraction(datetime, floorDate, ceilDate)

      if datetime.getTime() < @startDate.getTime() # out of range, left
        @clippedDate = true
        minX
      else if datetime.getTime() > @endDate.getTime() # out of range, right
        @clippedDate = true
        maxX
      else # in range
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
        @dateLabel x, @topMargin + @height, chrome.label if chrome.label

    ##
    # Draw label text at (x, y).
    dateLabel: (x, y, text) ->
      label = @paper.text x, y, text
      label.attr fill: @frameColor

    ##
    # Get date text for a bin
    binDateText: (bin) ->
      lastDay = @binner.nextTick(bin.date).addDays(-1)
      daysBetween = helpers.daysBetween(bin.date, lastDay)
      if daysBetween < 1 # single-day bucket: label the date
        I18n.l 'date.formats.medium', bin.date
      else if daysBetween < 7 # one-week bucket: label the start and end days; include the year only with the end day unless they're different
        I18n.t "%{start_date} - %{end_date}",
          start_date: I18n.l((if bin.date.getFullYear() == lastDay.getFullYear() then 'date.formats.short' else 'date.formats.medium'), bin.date)
          end_date: I18n.l('date.formats.medium', lastDay)
      else # one-month bucket; label the month and year
        I18n.l 'date.formats.medium_month', bin.date

