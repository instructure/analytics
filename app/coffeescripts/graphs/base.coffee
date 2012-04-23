define [
  'jquery'
  'vendor/graphael'
  'jquery.disableWhileLoading'
], ($, graphael) ->

  ##
  # Base class for all the analytics graphs (actual displayed graphs, not
  # components). Each graph should define a "graph" method that takes the
  # necessary parameters and renders the actual graph. Consumers of the graph
  # object can use "graph" directly if they have the necessary data, or if they
  # have one or more Promises for some of the necessary data, they can use
  # "graphDeferred". They should also define a "clickCB" for when cover regions
  # are clicked.

  defaultOptions =
    ##
    # Width, in pixels, of the graph, including margins. Required.
    width: null

    ##
    # Height, in pixels, of the graph, including margins. Required.
    height: null

    ##
    # Margin, in pixels, between the div borders and the graph frame. Can be
    # overridden for particular sides via the options below.
    margin: 5

    ##
    # Margin, in pixels, between the top and bottom div borders and the graph
    # frame. Can be overridden for particular sides via the options below.
    # Defaults to margin if unset.
    verticalMargin: null

    ##
    # Margin, in pixels, between the top div border and the graph frame.
    # Defaults to verticalMargin if unset.
    topMargin: null

    ##
    # Margin, in pixels, between the bottom div border and the graph frame.
    # Defaults to verticalMargin if unset.
    bottomMargin: null

    ##
    # Margin, in pixels, between the left and right div borders and the graph
    # frame. Can be overridden for particular sides via the options below.
    # Defaults to margin if unset.
    horizontalMargin: null

    ##
    # Margin, in pixels, between the left div border and the graph frame.
    # Defaults to horizontalMargin if unset.
    leftMargin: null

    ##
    # Margin, in pixels, between the right div border and the graph frame.
    # Defaults to horizontalMargin if unset.
    rightMargin: null

    ##
    # Color of the graph frame.
    frameColor: "#eee"

    ##
    # The color of the grid, if any. Not drawn if unset.
    gridColor: null

  class Base
    ##
    # Takes an element id on which to draw the graph and the options described
    # above.
    constructor: (@div, options) ->
      # check for required options
      throw new Error "width is required" unless options.width?
      throw new Error "height is required" unless options.height?

      # copy in recognized options with defaults
      for key, defaultValue of defaultOptions
        @[key] = options[key] ? defaultValue

      # these options have defaults based on other options
      @verticalMargin ?= @margin
      @topMargin ?= @verticalMargin
      @bottomMargin ?= @verticalMargin
      @horizontalMargin ?= @margin
      @leftMargin ?= @horizontalMargin
      @rightMargin ?= @horizontalMargin

      # instantiate and resize the paper
      @paper = graphael @div[0]
      @resize()

    ##
    # Take an object with width and/or height properties, sets the
    # corresponding properties of the graph, then resizes and clears the graphs
    # paper.
    resize: ({width, height}={}) ->
      @width = width if width?
      @height = height if height?
      @middle = @topMargin + @height / 2
      @paper.setSize @leftMargin + @width + @rightMargin, @topMargin + @height + @bottomMargin
      @reset()

    ##
    # Draw the graph's frame on the margins.
    drawFrame: ->
      border = @paper.rect @leftMargin, @topMargin, @width, @height
      border.attr stroke: @frameColor, fill: "none"

    ##
    # Resets the graph.
    reset: ->
      @paper.clear()
      @drawFrame()

    ##
    # Draw the graph. Each graph should override this. Each override should
    # call super as the first action and exit if the return value is false.
    # E.g. 'return unless super'.
    #
    # This base version checks if the data is still loading. If so, places a
    # spinner and queues to rerun once loaded. Returns false in this case to
    # indicate that the graph should not be drawn yet. Otherwise (the data is
    # fully ready), simply returns true to indicate the graph can be drawn.
    graph: (data) ->
      @reset()
      if data.loading?
        @div.disableWhileLoading(data.loading)
        data.loading.done => @graph data
        data.loading.fail -> # TODO: add error icon
        return false
      else
        return true
