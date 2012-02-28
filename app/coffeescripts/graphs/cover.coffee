define [ 'analytics/compiled/graphs/tooltip' ], (Tooltip) ->

  ##
  # Creates a transparent hover/click target from the region; a "cover" for
  # some graph element. Hovering the region displays a popup tooltip. Clicking
  # the cover triggers the provided click callback.
  class Cover
    constructor: (@graph, {region, tooltip, click}) ->
      # build tooltip popup that positions itself relative to the graph
      @tooltip = new Tooltip @graph.div, tooltip

      # make the region invisible and register event handlers
      region.attr stroke: "none", 'fill-opacity': 0, fill: '#000'
      region.mouseover @tooltip.show
      region.mouseout @tooltip.hide
      region.click click
