import $ from 'jquery'
import Tooltip from '../graphs/tooltip'

// Draws a horizontal bar with internal fill representing a count of events
// for a specific student.
export default class CountBar {
  constructor($el) {
    this.$el = $el
    this.reset()
  }

  // #
  // (Re)initialize with a fresh container and fill bar.
  reset() {
    this.$el.empty()
    this.paper = $('<span>')
      .addClass('paper')
      .appendTo(this.$el)
    this.fillBar = $('<span>').appendTo(this.paper)

    // attach tooltip that hangs below the bar when hovered
    this.tooltip = new Tooltip(this.paper, {
      x: 100,
      y: 8,
      direction: 'right'
    })
    this.paper.mouseover(this.tooltip.show)
    return this.paper.mouseout(this.tooltip.hide)
  }

  // #
  // Set the length of the fill bar proportional to the count/max ratio in the
  // given data.
  show(data) {
    this.tooltip.contents = this.tooltipContents(data)
    let width = 100 * (data.count / data.max)
    if (data.max <= 0) {
      width = 0
    }
    return this.fillBar.css({right: `${Math.round(100 - width)}%`})
  }
}
