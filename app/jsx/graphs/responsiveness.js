define [
  'underscore'
  'analytics/compiled/graphs/DateAlignedGraph'
  'analytics/compiled/graphs/cover'
  'compiled/str/TextHelper'
  'i18n!responsiveness'
  'str/htmlEscape'
], (_, DateAlignedGraph, Cover, {delimit}, I18n, htmlEscape) ->

  ##
  # Responsiveness visualizes the student's communication frequency with the
  # instructors of the class. A message icon represents a day in which the
  # student sent a message to an instructor or an instructor sent a message to
  # the student. Messages from the student are in the top track and messages
  # from instructors are in the bottom track.

  defaultOptions =

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

  class Responsiveness extends DateAlignedGraph
    ##
    # Takes an element and options, same as for DateAlignedGraph. Recognizes
    # the options described above in addition to the options for
    # DateAlignedGraph.
    constructor: (div, options) ->
      super

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # placement of tracks of markers
      @markerHeight = (@height - @topPadding - @bottomPadding - @gutterHeight) / 2 - @verticalMargin
      @studentTrack = @topMargin + @topPadding
      @instructorTrack = @studentTrack + @markerHeight + @gutterHeight
      @center = @instructorTrack - @gutterHeight / 2

    reset: ->
      super

      # label the tracks
      @paper.text(@leftMargin - 10, @topMargin, I18n.t("student")).attr
        fill: @frameColor
        transform: 'r-90'
        'text-anchor': 'end'

      @paper.text(@leftMargin - 10, @topMargin + @height - @bottomPadding, I18n.t("instructors")).attr
        fill: @frameColor
        transform: 'r-90'
        'text-anchor': 'start'

    ##
    # Graph the data.
    graph: (messaging) ->
      return unless super

      bins = _.filter messaging.bins, (bin) =>
        bin.date.between(@startDate, @endDate) &&
        bin.messages > 0

      _.each bins, @graphBin

      @finish()

    ##
    # Graph a single bin; i.e. a (day, track) pair. Fat arrowed because
    # it's called by _.each
    graphBin: (bin) =>
      switch bin.track
        when 'student' then @graphStudentBin bin
        when 'instructor' then @graphInstructorBin bin

    ##
    # Place a student marker for the given day.
    graphStudentBin: (bin) ->
      icon = @paper.path @studentPath bin.date
      icon.attr stroke: "white", fill: @studentColor
      @cover bin.date, @studentTrack, bin.messages

    ##
    # Place an instructor marker for the given day.
    graphInstructorBin: (bin) ->
      icon = @paper.path @instructorPath bin.date
      icon.attr stroke: "white", fill: @instructorColor
      @cover bin.date, @instructorTrack, bin.messages

    ##
    # Calculate the marker's bounding box (excluding carat) for a given day and
    # track.
    markerBox: (date, track) ->
      x = @binnedDateX date
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
    studentPath: (date) ->
      box = @markerBox date, @studentTrack
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
    instructorPath: (date) ->
      box = @markerBox date, @instructorTrack
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
    cover: (date, track, value) ->
      box = @markerBox date
      [top, bottom, direction, klass] = switch track
        when @studentTrack then [@topMargin, @center, 'down', 'student']
        when @instructorTrack then [@center, @topMargin + @height, 'up', 'instructor']
      new Cover this,
        region: @paper.rect box.left, top, @markerWidth, bottom - top
        classes: [klass, I18n.l('date.formats.default', date)]
        tooltip:
          contents: @tooltip(date, value)
          x: box.carat
          y: @center
          direction: direction

    ##
    # Build the text for a bin's tooltip.
    tooltip: (date, value) ->
      $.raw "#{htmlEscape I18n.l 'date.formats.medium', date}<br/>#{htmlEscape I18n.t({one: "1 message", other: "%{count} messages"}, {count: value})}"
