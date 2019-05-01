define [
  'analytics/compiled/graphs/tooltip'
], (Tooltip) ->

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

      # attach tooltip that hangs below the bar when hovered
      @tooltip = new Tooltip @paper,
        x: 100
        y: 8
        direction: 'right'
      @paper.mouseover @tooltip.show
      @paper.mouseout @tooltip.hide

    ##
    # Set the length of the fill bar proportional to the count/max ratio in the
    # given data.
    show: (data) ->
      @tooltip.contents = @tooltipContents(data)
      width = 100 * (data.count / data.max)
      width = 0 if data.max <= 0
      @fillBar.css right: Math.round(100 - width) + '%'
