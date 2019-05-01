define [ 'analytics/compiled/graphs/tooltip' ], (Tooltip) ->

  ##
  # Creates a transparent hover/click target from the region; a "cover" for
  # some graph element. Hovering the region displays a popup tooltip. Clicking
  # the cover triggers the provided click callback.
  class Cover
    constructor: (@graph, {region, classes, tooltip, click}) ->
      # build tooltip popup that positions itself relative to the graph
      @tooltip = new Tooltip @graph.div, tooltip

      # what classes to tag the region with
      classes ?= []
      classes = [classes] if typeof classes is 'string'
      classes.push 'cover'
      classes = classes.join(' ')
      $(region.node).attr class: classes

      # make the region invisible and register event handlers
      region.attr stroke: "none", 'fill-opacity': 0, fill: '#000'
      $node = $(region.node)
      $node.mouseover @tooltip.show
      $node.mouseout @tooltip.hide
      $node.click click
