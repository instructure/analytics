import $ from 'jquery'
import Tooltip from '../graphs/tooltip'

// #
// Creates a transparent hover/click target from the region; a "cover" for
// some graph element. Hovering the region displays a popup tooltip. Clicking
// the cover triggers the provided click callback.
export default class Cover {
  constructor(graph, {region, classes, tooltip, click}) {
    // build tooltip popup that positions itself relative to the graph
    this.graph = graph
    this.tooltip = new Tooltip(this.graph.div, tooltip)

    // what classes to tag the region with
    if (classes == null) classes = []
    if (typeof classes === 'string') classes = [classes]
    classes.push('cover')
    classes = classes.join(' ')
    $(region.node).attr({class: classes})

    // make the region invisible and register event handlers
    region.attr({stroke: 'none', 'fill-opacity': 0, fill: '#000'})
    const $node = $(region.node)
    $node.mouseover(this.tooltip.show)
    $node.mouseout(this.tooltip.hide)
    $node.click(click)
  }
}
