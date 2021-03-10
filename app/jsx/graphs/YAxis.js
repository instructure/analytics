import I18n from '@canvas/i18n'

export default class YAxis {
  constructor(host, opts = {}) {
    this.host = host
    ;[this.min, this.max] = Array.from(opts.range)
    this.style = opts.style != null ? opts.style : 'default'
    this.title = opts.title

    // scales for most graphs are multiples of 1 item. for percentage graphs
    // we start at 0.1%.
    const scale = this.style === 'percent' ? 0.001 : 1

    // choose the first step size from 1, 2, 5, 10, 20, 50, 100, etc. such
    // that 5 steps (scaled) exceeds or equals the size of the range. this
    // rate of growth "feels natural" and guarantees at least 2 labeled ticks
    // (at least 3 if ticks fall on both the min and max of the range) and at
    // most 6 (only 5 if either of the min or max are "off-tick")
    this.tickStep = 1
    this.labelFrequency = 1
    const growth = [2, 2.5, 2]
    let i = 0
    while (this.tickStep * scale * 5 < this.max) {
      this.tickStep *= growth[i % 3]
      i += 1
    }

    // if the step size is at least 5 (and thus a multiple of 5), draw
    // five times as many ticks, but only label at the original rate (2 to 5
    // labels).
    if (this.tickStep > 1) {
      this.tickStep /= 5
      this.labelFrequency = 5
    }

    // scale it down (or up)
    this.tickStep *= scale
  }

  // #
  // Convert a tick number to a value (assuming tick number 0 = value 0).
  tickValue(tick) {
    return tick * this.tickStep
  }

  // #
  // Label every @labelFrequency-th tick with a label and grid line.
  draw() {
    let value
    this.width = 0

    let j = Math.ceil(this.min / this.tickStep)
    while ((value = this.tickValue(j)) <= this.max) {
      const y = this.host.valueY(value)
      if (j % this.labelFrequency === 0) {
        this.line(y)
        this.label(y, this.labelText(value))
      }
      j += 1
    }

    if (this.title) {
      return this.host.drawYLabel(this.title, {offset: this.width})
    }
  }

  // #
  // Draw a grid line at y on the host, form left to right margin.
  line(y) {
    return this.host.paper
      .path(['M', this.host.leftMargin, y, 'l', this.host.width, 0])
      .attr({stroke: this.host.gridColor})
  }

  // #
  // Convert a value into a label.
  labelText(value) {
    if (this.style === 'percent') {
      // scale up to percentage and add % character
      return I18n.n(value * 100, {percentage: true})
    } else {
      // find power of 1000 to replace with suffix. we really shouldn't need
      // anything bigger than billion (B)
      let power = Math.floor(Math.log(value) / Math.log(1000))
      if (power < 0) power = 0
      if (power > 3) power = 3

      // get the correct suffix
      const suffix = (() => {
        switch (power) {
          case 0:
            return ''
          case 1:
            return 'k'
          case 2:
            return 'M'
          case 3:
            return 'B'
        }
      })()

      // take out the power that'll be represented by the suffix and add the
      // suffix
      return I18n.n(value / Math.pow(1000, power)) + suffix
    }
  }

  // #
  // Draw a y-axis label at y on the host, just outside the left margin.
  label(y, text) {
    const label = this.host.paper.text(this.host.leftMargin - 5, y, text)
    label.attr({
      fill: this.host.frameColor,
      'text-anchor': 'end'
    })
    return (this.width = Math.max(this.width, label.getBBox().width))
  }
}

YAxis.prototype.tickSize = 5
