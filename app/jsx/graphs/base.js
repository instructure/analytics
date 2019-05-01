define [
  'graphael'
  'jquery.disableWhileLoading'
], (graphael) ->

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
    # Padding, in pixels, between the frame and the graph contents.
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
    # contents. Must be large enough to accomodate X-axis labels.
    bottomPadding: 10

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
    # Color of the graph frame.
    frameColor: "#eee"

    ##
    # The color of the grid, if any. Not drawn if unset.
    gridColor: null

    ##
    # The color of the warning message, if any.
    warningColor: 'red'

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

      @verticalPadding ?= @padding
      @topPadding ?= @verticalPadding
      @bottomPadding ?= @verticalPadding
      @horizontalPadding ?= @padding
      @leftPadding ?= @horizontalPadding
      @rightPadding ?= @horizontalPadding

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
    # Draw the graph's baseline.
    drawBaseline: ->
      @paper.path([
        "M", @leftMargin, @topMargin + @height - @bottomPadding,
        "l", @width, 0
      ]).attr stroke: @frameColor

    ##
    # Draw a label describing the x-axis. Centered left-to-right. opts.offset
    # informs it of the height of the x value labels, if any, so it can be
    # placed below of those.
    drawXLabel: (label, opts={}) ->
      y = @topMargin + @height
      y += opts.offset + 5 if opts.offset && opts.offset > 0
      @paper.text(@leftMargin + @width / 2, y, label).attr fill: @frameColor

    ##
    # Draw a label describing the y-axis. Centered top-to-bottom and written
    # sideways. opts.offset informs it of the width of the y value labels, if
    # any, so it can be placed left of those.
    drawYLabel: (label, opts={}) ->
      x = @leftMargin - 10
      x -= opts.offset + 5 if opts.offset && opts.offset > 0
      @paper.text(x, @topMargin + @height / 2, label).attr
        fill: @frameColor
        transform: 'r-90'

    drawWarning: (label) ->
      x = @leftMargin + @width / 2
      @paper.text(x, @topPadding/2, label).attr
        fill: @warningColor

    ##
    # Draw a shape centered on the given coordinates.
    # attrs is an object:
    #   shape: one of 'square', 'triangle', 'circle'
    #   radius: maximum extent of shape from the given coordinates, along either axis
    #   color: outline color of the shape
    #   fill: fill color of the shape (defaults to outline color)
    #   outline: width of the outline in pixels, default 2
    drawShape: (x, y, radius, attrs) ->
      fill = attrs.fill || attrs.color
      outline = attrs.outline || 2
      if attrs.shape is 'square'
        @drawSquare(x, y, radius, attrs.color, fill, outline)
      else if attrs.shape is 'triangle'
        @drawTriangle(x, y, radius, attrs.color, fill, outline)
      else
        @drawCircle(x, y, radius, attrs.color, fill, outline)

    drawSquare: (x, y, radius, color, fill, outline) ->
      path = ["M", x - radius, y - radius,
              "L", x + radius, y - radius,
              "L", x + radius, y + radius,
              "L", x - radius, y + radius,
              "z"]
      square = @paper.path path
      square.attr stroke: color, fill: fill, 'stroke-width': outline

    drawTriangle: (x, y, radius, color, fill, outline) ->
      path = ["M", x, y - radius,
              "L", x + radius, y + radius,
              "L", x - radius, y + radius,
              "z"]
      triangle = @paper.path path
      triangle.attr stroke: color, fill: fill, 'stroke-width': outline

    drawCircle: (x, y, radius, color, fill, outline) ->
      circle = @paper.circle x, y, radius
      circle.attr stroke: color, fill: fill, 'stroke-width': outline

    ##
    # Resets the graph.
    reset: ->
      @paper.clear()

    ##
    # Puts finishing touches on the graph. Call at the end of your derived graph()
    finish: ->
      @drawBaseline()

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
