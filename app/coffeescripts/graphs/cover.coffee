define [
  'jquery'
  'analytics/jst/tooltip'
], ($, template) ->

  ##
  # Creates a transparent hover/click target from the region; a "cover" for
  # some graph element. Hovering the region displays a popup tooltip. Clicking
  # the cover triggers the provided click callback.
  class Cover
    ##
    # Takes an element id on which to draw the graph and the options described
    # above.
    constructor: (@graph, {region, tooltip, click}) ->
      # build tooltip popup
      @tooltip = @buildTooltip tooltip

      # make the region invisible and register event handlers
      region.attr stroke: "none", 'fill-opacity': 0, fill: '#000'
      region.mouseover @mouseover
      region.mouseout @mouseout
      region.click click

    ##
    # Create a tooltip from the template, append it to body, then add the caret
    # on the appropriate side and position so the tip of the carat is at (x, y)
    # relative to @graph.
    buildTooltip: ({contents, x, y, direction}) ->
      tooltip = $(template contents: contents)
      tooltip.appendTo(document.body)

      switch direction
        when 'up' then tooltip.addClass 'carat-bottom'
        when 'down' then tooltip.addClass 'carat-top'

      dx = tooltip.outerWidth() / 2
      dy = switch direction
        when 'up' then tooltip.outerHeight() + 11
        when 'down' then -11

      position = @graph.div.offset()
      position.left += Math.round(x - dx)
      position.top += Math.round(y - dy)
      tooltip.offset position

      tooltip

    mouseover: =>
      @tooltip.show()

    mouseout: =>
      @tooltip.hide()
