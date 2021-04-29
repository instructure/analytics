import $ from 'jquery'
import htmlEscape from 'html-escape'

// #
// Global shared tooltip elements. The $tooltip will be reused by each Tooltip
// object we create (only one tooltip will ever be showing; javascript's mouse
// model ensures the old cover's mouseout will fire before the new cover's
// mouseover).
const $carat = $('<span class="ui-menu-carat"><span /></span>')
const $tooltip = $('<div class="analytics-tooltip" />')

// #
// Create a tooltip.
export default class Tooltip {
  constructor(reference, {contents, x, y, direction}) {
    this.show = this.show.bind(this)
    this.reference = reference
    this.contents = contents
    this.x = x
    this.y = y
    this.direction = direction
  }

  // #
  // Populate the global tooltip element with this Tooltip's info.
  populate() {
    $tooltip.attr({class: 'analytics-tooltip'})
    switch (this.direction) {
      case 'up':
        $tooltip.addClass('carat-bottom')
        break
      case 'down':
        $tooltip.addClass('carat-top')
        break
      case 'left':
        $tooltip.addClass('carat-right')
        break
      case 'right':
        $tooltip.addClass('carat-left')
        break
    }
    // can remove superfluous var and toString once xsspalooza lands in canvas
    const contentsHtml = htmlEscape(this.contents).toString()
    $tooltip.html(contentsHtml)
    return $tooltip.prepend($carat)
  }

  // #
  // Position the global tooltip elements for this Tooltip.
  position() {
    const dx = (() => {
      switch (this.direction) {
        case 'up':
          return $tooltip.outerWidth() / 2
        case 'down':
          return $tooltip.outerWidth() / 2
        case 'left':
          return $tooltip.outerWidth() + 11
        case 'right':
          return -11
      }
    })()

    const dy = (() => {
      switch (this.direction) {
        case 'up':
          return $tooltip.outerHeight() + 11
        case 'down':
          return -11
        case 'left':
          return $tooltip.outerHeight() / 2
        case 'right':
          return $tooltip.outerHeight() / 2
      }
    })()

    const position = this.reference.offset()
    position.left += Math.round(this.x - dx)
    position.top += Math.round(this.y - dy)
    return $tooltip.offset(position)
  }

  // #
  // Populate, attach to the document, and position the tooltip.
  show() {
    this.populate()
    $tooltip.appendTo(document.body)
    return this.position()
  }

  // #
  // Remove the tooltip from the page until the next mouseover.
  hide() {
    return $tooltip.remove()
  }
}
