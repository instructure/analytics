define [
  'analytics/compiled/graphs/base'
  'analytics/compiled/helpers'
  'i18nObj'
], (Base, helpers, I18n) ->

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

      # check for required options
      throw new Error "startDate is required" unless options.startDate?
      throw new Error "endDate is required" unless options.endDate?

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # center of start diamond = @leftMargin + @leftPadding
      # center of end diamond = @leftMargin + @width - @rightPadding
      @x0 = @leftMargin + @leftPadding
      @daySpacing = (@width - @leftPadding - @rightPadding) / helpers.daysBetween(@startDate, @endDate)

    ##
    # Reset the graph chrome. Adds an x-axis with daily ticks and weekly (on
    # Mondays) labels.
    reset: ->
      super
      @drawDateAxis()

    ##
    # Convert a date to an x-coordinate.
    dateX: (date) ->
      @x0 + helpers.daysBetween(@startDate, date) * @daySpacing

    ##
    # Draw a guide along the x-axis. Each day gets a pair of ticks; one from
    # the top of the frame, the other from the bottom. The ticks are replaced
    # by a full vertical grid line on Mondays, accompanied by a label.
    drawDateAxis: ->
      # skip if we haven't set start/end dates yet (@reset will be called by
      # Base's constructor before we set startDate or endDate)
      return unless @startDate? && @endDate?
      date = @startDate.clone()
      while date <= @endDate
        x = @dateX date
        if date.getDay() is 1
          @drawWeekLine x
          @dateLabel x, @topMargin + @height + 10, date.getDate()
          unless month? && date.getMonth() is month.getMonth()
            style = if month? && date.getYear() is month.getYear() then "short_month" else "medium_month"
            @dateLabel x, @topMargin - 10, I18n.l("date.formats.#{style}", date)
            month = date.clone()
        else
          @drawDayTick x
        date.addDays 1

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
