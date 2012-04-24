define [
  'underscore'
  'analytics/compiled/graphs/base'
  'analytics/compiled/graphs/cover'
  'analytics/compiled/graphs/date_axis'
  'analytics/compiled/helpers'
  'i18nObj'
], (_, Base, Cover, dateAxis, helpers, I18n) ->

  ##
  # Responsiveness visualizes the student's communication frequency with the
  # instructors of the class. A message icon represents a day in which the
  # student sent a message to an instructor or an instructor sent a message to
  # the student. Messages from the student are in the top track and messages
  # from instructors are in the bottom track.

  defaultOptions =

    ##
    # The date for the left end of the graph. Required.
    startDate: null

    ##
    # The date for the right end of the graph. Required.
    endDate: null

    ##
    # Padding, in pixels, between the frame and the graph contents. Note: On
    # the left and right, this is space from the frame to the carat of the
    # message icon, not the outer edge. This is necessary to keep the date
    # graphs aligned.
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
    # The size of the vertical gutter between the two tracks, in pixels.
    gutterHeight: 10

    ##
    # The width of the message icon, in pixels.
    markerWidth: 30

    ##
    # The distance, in pixels, from the carat to the right edge of the marker.
    caratOffset: 7

    ##
    # The size of the carat, in pixels.
    caratSize: 3

    ##
    # The fill color of the icons in the student track.
    studentColor: "lightblue"

    ##
    # The fill color of the icons in the instructor track.
    instructorColor: "lightgreen"

  class Responsiveness extends Base
    ##
    # Takes an element id and options, same as for Base. Recognizes the options
    # described above in addition to the options for Base.
    constructor: (div, options) ->
      super

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

      # carat of start marker = @leftMargin + leftPadding
      # carat of end marker = @leftMargin + @width - rightPadding
      @x0 = @leftMargin + @leftPadding
      @daySpacing = (@width - @leftPadding - @rightPadding) / (@endDay - @startDay)

      # placement of tracks of markers
      @markerHeight = (@height - @topPadding - @bottomPadding - @gutterHeight) / 2
      @studentTrack = @topMargin + @topPadding
      @instructorTrack = @studentTrack + @markerHeight + @gutterHeight
      @center = @instructorTrack - @gutterHeight / 2

    ##
    # Convert a Date object to a day index.
    day: (date) ->
      if date?
        helpers.dateToDays(date)
      else
        null

    ##
    # Reset the graph chrome.
    reset: ->
      super
      dateAxis this

    ##
    # Graph the data.
    graph: (messaging) ->
      return unless super

      messages = @binMessages messaging.messages
      _.each messages, @graphDay

    ##
    # Graph a single day. Fat arrowed because it's called by _.each
    graphDay: (counts, day) =>
      if counts.student > 0
        @drawStudentMarker day
        @cover day, @studentTrack, counts.student
      if counts.instructor > 0
        @drawInstructorMarker day
        @cover day, @instructorTrack, counts.instructor

    ##
    # Bin the messages by day and track.
    binMessages: (messages) ->
      binned = {}
      for date, counts of messages
        day = @day Date.parse date
        if day >= @startDay && day <= @endDay
          binned[day] ?= { student: 0, instructor: 0 }
          if counts.studentMessages?
            binned[day].student ?= 0
            binned[day].student += counts.studentMessages
          if counts.instructorMessages?
            binned[day].instructor ?= 0
            binned[day].instructor += counts.instructorMessages
      binned

    ##
    # Place a student marker for the given day.
    drawStudentMarker: (day) ->
      icon = @paper.path @studentPath day
      icon.attr stroke: "white", fill: @studentColor

    ##
    # Place an instructor marker for the given day.
    drawInstructorMarker: (day) ->
      icon = @paper.path @instructorPath day
      icon.attr stroke: "white", fill: @instructorColor

    ##
    # Convert a day index to an x-coordinate.
    dayX: (day) ->
      @x0 + (day - @startDay) * @daySpacing

    ##
    # Convert a date to an x-coordinate.
    dateX: (date) ->
      @dayX @day date

    ##
    # Calculate the marker's bounding box (excluding carat) for a given day and
    # track.
    markerBox: (day, track) ->
      x = @dayX day
      carat: x
      right: x + @caratOffset
      left: x + @caratOffset - @markerWidth
      top: track
      bottom: track + @markerHeight

    ##
    # Calculate the corner centers for a given bounding box.
    markerCorners: (box) ->
      left: box.left + 3
      right: box.right - 3
      top: box.top + 3
      bottom: box.bottom - 3

    ##
    # Calculate the carat values for a given bounding box and carat direction.
    markerCarat: (box, direction) ->
      left: box.carat - @caratSize
      right: box.carat
      tip: switch direction
        when 'up' then box.top - @caratSize
        when 'down' then box.bottom + @caratSize

    ##
    # Build an SVG path for a student marker on the given day.
    studentPath: (day) ->
      box = @markerBox day, @studentTrack
      corners = @markerCorners box
      carat = @markerCarat box, 'down'

      [ 'M', corners.left, box.top,     # start at the top-left
        'L', corners.right, box.top,    # across the top
        'A', 3, 3, 0, 0, 1,
             box.right, corners.top,    # around the top-right corner
        'L', box.right, corners.bottom, # down the right side
        'A', 3, 3, 0, 0, 1,
             corners.right, box.bottom, # around the bottom-right corner
        'L', carat.right, box.bottom,   # across the bottom to the carat
             carat.right, carat.tip,    # down to the carat tip
             carat.left, box.bottom,    # back up to the bottom
             corners.left, box.bottom,  # across the rest of the bottom
        'A', 3, 3, 0, 0, 1,
             box.left, corners.bottom,  # around the bottom-left corner
        'L', box.left, corners.top,     # up the left side
        'A', 3, 3, 0, 0, 1,
             corners.left, box.top,     # around the top-left corner
        'z' ]                           # done

    ##
    # Build an SVG path for an instructor marker on the given day.
    instructorPath: (day) ->
      box = @markerBox day, @instructorTrack
      corners = @markerCorners box
      carat = @markerCarat box, 'up'

      [ 'M', corners.left, box.top,     # start at the top-left
        'L', carat.left, box.top,       # across the top to the carat
             carat.right, carat.tip,    # up to the carat tip
             carat.right, box.top,      # back down to the top
             corners.right, box.top,    # across the rest of the top
        'A', 3, 3, 0, 0, 1,
             box.right, corners.top,    # around the top-right corner
        'L', box.right, corners.bottom, # down the right side
        'A', 3, 3, 0, 0, 1,
             corners.right, box.bottom, # around the bottom-right corner
        'L', corners.left, box.bottom,  # across the bottom
        'A', 3, 3, 0, 0, 1,
             box.left, corners.bottom,  # around the bottom-left corner
        'L', box.left, corners.top,     # up the left side
        'A', 3, 3, 0, 0, 1,
             corners.left, box.top,     # around the top-left corner
        'z' ]                           # done

    ##
    # Create a tooltip for a day and track bin.
    cover: (day, track, value) ->
      box = @markerBox day
      [top, bottom, direction, klass] = switch track
        when @studentTrack then [@topMargin, @center, 'down', 'student']
        when @instructorTrack then [@center, @topMargin + @height, 'up', 'instructor']
      new Cover this,
        region: @paper.rect box.left, top, @markerWidth, bottom - top
        classes: [klass, I18n.l('date.formats.default', helpers.dayToDate day)]
        tooltip:
          contents: @tooltip(day, value)
          x: box.carat
          y: @center
          direction: direction

    ##
    # Build the text for a bin's tooltip.
    tooltip: (day, value) ->
      noun = if value is 1 then "message" else "messages"
      "#{helpers.dayToDate(day).toDateString()}<br/>#{value} #{noun}"
