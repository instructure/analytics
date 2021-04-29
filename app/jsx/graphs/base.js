import graphael from 'graphael'
import '@canvas/jquery/jquery.disableWhileLoading'

// #
// Base class for all the analytics graphs (actual displayed graphs, not
// components). Each graph should define a "graph" method that takes the
// necessary parameters and renders the actual graph. Consumers of the graph
// object can use "graph" directly if they have the necessary data, or if they
// have one or more Promises for some of the necessary data, they can use
// "graphDeferred". They should also define a "clickCB" for when cover regions
// are clicked.

const defaultOptions = {
  // #
  // Width, in pixels, of the graph, including margins. Required.
  width: null,

  // #
  // Height, in pixels, of the graph, including margins. Required.
  height: null,

  // #
  // Margin, in pixels, between the div borders and the graph frame. Can be
  // overridden for particular sides via the options below.
  margin: 5,

  // #
  // Margin, in pixels, between the top and bottom div borders and the graph
  // frame. Can be overridden for particular sides via the options below.
  // Defaults to margin if unset.
  verticalMargin: null,

  // #
  // Margin, in pixels, between the top div border and the graph frame.
  // Defaults to verticalMargin if unset.
  topMargin: null,

  // #
  // Margin, in pixels, between the bottom div border and the graph frame.
  // Defaults to verticalMargin if unset.
  bottomMargin: null,

  // #
  // Margin, in pixels, between the left and right div borders and the graph
  // frame. Can be overridden for particular sides via the options below.
  // Defaults to margin if unset.
  horizontalMargin: null,

  // #
  // Margin, in pixels, between the left div border and the graph frame.
  // Defaults to horizontalMargin if unset.
  leftMargin: null,

  // #
  // Margin, in pixels, between the right div border and the graph frame.
  // Defaults to horizontalMargin if unset.
  rightMargin: null,

  // #
  // Padding, in pixels, between the frame and the graph contents.
  padding: 5,

  // #
  // Padding, in pixels, between the top and bottom of the frame and the graph
  // contents. Can be overridden for particular sides via the options below.
  // Defaults to padding if unset.
  verticalPadding: null,

  // #
  // Padding, in pixels, between the top of the frame and the graph contents.
  // Defaults to verticalPadding if unset.
  topPadding: null,

  // #
  // Padding, in pixels, between the bottom of the frame and the graph
  // contents. Must be large enough to accomodate X-axis labels.
  bottomPadding: 10,

  // #
  // Padding, in pixels, between the left and right of the frame and the graph
  // contents. Can be overridden for particular sides via the options below.
  // Defaults to padding if unset.
  horizontalPadding: null,

  // #
  // Padding, in pixels, between the left of the frame and the graph contents.
  // Defaults to horizontalPadding if unset.
  leftPadding: null,

  // #
  // Padding, in pixels, between the right of the frame and the graph
  // contents. Defaults to horizontalPadding if unset.
  rightPadding: null,

  // #
  // Color of the graph frame.
  frameColor: '#eee',

  // #
  // The color of the grid, if any. Not drawn if unset.
  gridColor: null,

  // #
  // The color of the warning message, if any.
  warningColor: 'red'
}

export default class Base {
  // #
  // Takes an element id on which to draw the graph and the options described
  // above.
  constructor(div, options) {
    // check for required options
    this.div = div
    if (options.width == null) throw new Error('width is required')
    if (options.height == null) throw new Error('height is required')

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    // these options have defaults based on other options
    if (this.verticalMargin == null) this.verticalMargin = this.margin
    if (this.topMargin == null) this.topMargin = this.verticalMargin
    if (this.bottomMargin == null) this.bottomMargin = this.verticalMargin
    if (this.horizontalMargin == null) this.horizontalMargin = this.margin
    if (this.leftMargin == null) this.leftMargin = this.horizontalMargin
    if (this.rightMargin == null) this.rightMargin = this.horizontalMargin

    if (this.verticalPadding == null) this.verticalPadding = this.padding
    if (this.topPadding == null) this.topPadding = this.verticalPadding
    if (this.bottomPadding == null) this.bottomPadding = this.verticalPadding
    if (this.horizontalPadding == null) this.horizontalPadding = this.padding
    if (this.leftPadding == null) this.leftPadding = this.horizontalPadding
    if (this.rightPadding == null) this.rightPadding = this.horizontalPadding

    // instantiate and resize the paper
    this.paper = graphael(this.div[0])
    this.resize()
  }

  // #
  // Take an object with width and/or height properties, sets the
  // corresponding properties of the graph, then resizes and clears the graphs
  // paper.
  resize(param = {}) {
    const {width, height} = param
    if (width != null) this.width = width
    if (height != null) this.height = height
    this.middle = this.topMargin + this.height / 2
    this.paper.setSize(
      this.leftMargin + this.width + this.rightMargin,
      this.topMargin + this.height + this.bottomMargin
    )
    return this.reset()
  }

  // #
  // Draw the graph's baseline.
  drawBaseline() {
    return this.paper.path([
      "M", this.leftMargin, (this.topMargin + this.height) - this.bottomPadding,
      "l", this.width, 0
    ]).attr({stroke: this.frameColor});
  }

  // #
  // Draw a label describing the x-axis. Centered left-to-right. opts.offset
  // informs it of the height of the x value labels, if any, so it can be
  // placed below of those.
  drawXLabel(label, opts = {}) {
    let y = this.topMargin + this.height
    if (opts.offset && opts.offset > 0) y += opts.offset + 5
    return this.paper.text(this.leftMargin + this.width / 2, y, label).attr({fill: this.frameColor})
  }

  // #
  // Draw a label describing the y-axis. Centered top-to-bottom and written
  // sideways. opts.offset informs it of the width of the y value labels, if
  // any, so it can be placed left of those.
  drawYLabel(label, opts = {}) {
    let x = this.leftMargin - 10
    if (opts.offset && opts.offset > 0) x -= opts.offset + 5
    return this.paper.text(x, this.topMargin + this.height / 2, label).attr({
      fill: this.frameColor,
      transform: 'r-90'
    })
  }

  drawWarning(label) {
    const x = this.leftMargin + this.width / 2
    return this.paper.text(x, this.topPadding / 2, label).attr({
      fill: this.warningColor
    })
  }

  // #
  // Draw a shape centered on the given coordinates.
  // attrs is an object:
  //   shape: one of 'square', 'triangle', 'circle'
  //   radius: maximum extent of shape from the given coordinates, along either axis
  //   color: outline color of the shape
  //   fill: fill color of the shape (defaults to outline color)
  //   outline: width of the outline in pixels, default 2
  drawShape(x, y, radius, attrs) {
    const fill = attrs.fill || attrs.color
    const outline = attrs.outline || 2
    if (attrs.shape === 'square') {
      return this.drawSquare(x, y, radius, attrs.color, fill, outline)
    } else if (attrs.shape === 'triangle') {
      return this.drawTriangle(x, y, radius, attrs.color, fill, outline)
    } else {
      return this.drawCircle(x, y, radius, attrs.color, fill, outline)
    }
  }

  drawSquare(x, y, radius, color, fill, outline) {
    const path = ["M", x - radius, y - radius,
            "L", x + radius, y - radius,
            "L", x + radius, y + radius,
            "L", x - radius, y + radius,
            "z"];
    const square = this.paper.path(path);
    return square.attr({stroke: color, fill, 'stroke-width': outline});
  }

  drawTriangle(x, y, radius, color, fill, outline) {
    const path = ["M", x, y - radius,
            "L", x + radius, y + radius,
            "L", x - radius, y + radius,
            "z"];
    const triangle = this.paper.path(path);
    return triangle.attr({stroke: color, fill, 'stroke-width': outline});
  }

  drawCircle(x, y, radius, color, fill, outline) {
    const circle = this.paper.circle(x, y, radius)
    return circle.attr({stroke: color, fill, 'stroke-width': outline})
  }

  // #
  // Resets the graph.
  reset() {
    return this.paper.clear()
  }

  // #
  // Puts finishing touches on the graph. Call at the end of your derived graph()
  finish() {
    return this.drawBaseline()
  }

  // #
  // Draw the graph. Each graph should override this. Each override should
  // call super as the first action and exit if the return value is false.
  // E.g. 'return unless super'.
  //
  // This base version checks if the data is still loading. If so, places a
  // spinner and queues to rerun once loaded. Returns false in this case to
  // indicate that the graph should not be drawn yet. Otherwise (the data is
  // fully ready), simply returns true to indicate the graph can be drawn.
  graph(data) {
    this.reset()
    if (data.loading != null) {
      this.div.disableWhileLoading(data.loading)
      data.loading.done(() => this.graph(data))
      data.loading.fail(() => {}) // TODO: add error icon
      return false
    } else {
      return true
    }
  }
}
