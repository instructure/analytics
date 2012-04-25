define ->

  ##
  # Draws a horizontal bar with internal fill representing a count of events
  # for a specific student.
  class CountBar
    constructor: (@$el) ->
      @reset()

    ##
    # (Re)initialize with a fresh container and fill bar.
    reset: ->
      @$el.empty()
      @paper = $('<span>').addClass('paper').appendTo(@$el)
      @fillBar = $('<span>').appendTo(@paper)

    ##
    # Set the length of the fill bar proportional to the count/max ratio in the
    # given data.
    show: (data) ->
      width = 100 * (data.count / data.max)
      @fillBar.css right: Math.round(100 - width) + '%'
