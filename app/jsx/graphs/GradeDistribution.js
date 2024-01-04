/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {each, map} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import Base from './base'
import Cover from './cover'
import YAxis from './YAxis'

const I18n = useI18nScope('grade_distribution')

// #
// GradeDistribution visualizes the distribution of grades across all students
// enrollments in department courses.
const defaultOptions = {
  // #
  // The color of the line graph.
  strokeColor: '#b1c6d8',

  // #
  // The fill color of the area under the line graph
  areaColor: 'lightblue',
}

export default class GradeDistribution extends Base {
  // #
  // Takes an element and options, same as for Base. Recognizes the options
  // described above in addition to the options for Base.
  constructor(div, options) {
    super(...arguments)

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    // left edge of leftmost bar diamond = @leftMargin + @leftPadding
    this.x0 = this.leftMargin + this.leftPadding

    // base of bars = @topmargin + @height - @bottompadding
    this.base = this.topMargin + this.height - this.bottomPadding

    // always graphing scores from 0 to 100
    this.scoreSpacing = (this.width - this.leftPadding - this.rightPadding) / 100
  }

  // #
  // Add X-axis to reset.
  reset() {
    super.reset(...arguments)
    return this.drawXAxis()
  }

  // #
  // Graph the data.
  graph(distribution) {
    if (!super.graph(...arguments)) {
      return
    }

    // scale the y-axis
    const max = this.scaleToData(distribution.values)
    this.yAxis.draw()

    // x label
    this.drawXLabel(I18n.t('Grades'), {offset: this.labelHeight})

    // build path for distribution line
    let path = map(distribution.values, (value, score) => {
      if (score === 0) value = Math.min(value, max)
      return [score === 0 ? 'M' : 'L', this.scoreX(score), this.valueY(value)]
    })

    // stroke the line
    this.paper.path(path).attr({
      stroke: this.strokeColor,
      'stroke-width': 2,
      'stroke-linejoin': 'round',
      'stroke-linecap': 'round',
      'stroke-dasharray': '',
    })

    // extend the path to close around the area under the line
    path = path.concat([
      ['L', this.scoreX(100), this.valueY(0)],
      ['L', this.scoreX(0), this.valueY(0)],
      ['z'],
    ])

    // fill that area
    this.paper.path(path).attr({
      stroke: 'none',
      fill: this.areaColor,
    })

    // add covers
    each(distribution.values, (value, score) => this.cover(score, value))

    return this.finish()
  }

  // #
  // Calculate the x-coordinate of a score, in pixels.
  scoreX(score) {
    return this.x0 + score * this.scoreSpacing
  }

  // #
  // Calculate the y-coordinate of a value, in pixels.
  valueY(value) {
    return this.base - value * this.countSpacing
  }

  // #
  // Choose appropriate scale for the y-dimension so as to put the tallest
  // point just at the top of the graph.
  scaleToData(values) {
    let max = Math.max(...Array.from(values.slice(1) || []))
    if (max == null || !(max > 0)) max = 0.001
    this.countSpacing = (this.height - this.topPadding - this.bottomPadding) / max
    this.yAxis = new YAxis(this, {range: [0, max], style: 'percent'})
    return max
  }

  // #
  // Draw a guide along the x-axis. Tick and label every 5 scores.
  drawXAxis(_bins) {
    let i = 0
    return (() => {
      const result = []
      while (i <= 100) {
        const x = this.scoreX(i)
        this.labelTick(x, i)
        result.push((i += 5))
      }
      return result
    })()
  }

  // #
  // Draw label text at (x, y).
  labelTick(x, text) {
    const y = this.topMargin + this.height
    const label = this.paper.text(x, y, text)
    label.attr({fill: this.frameColor})
    return (this.labelHeight = label.getBBox().height)
  }

  // #
  // Create a tooltip for a score.
  cover(score, value) {
    const x = this.scoreX(score)
    return new Cover(this, {
      region: this.paper.rect(
        x - this.scoreSpacing / 2,
        this.topMargin,
        this.scoreSpacing,
        this.height
      ),
      tooltip: {
        contents: this.tooltip(score, value),
        x,
        y: this.base,
        direction: 'down',
      },
    })
  }

  // #
  // Build the text for the score tooltip.
  tooltip(score, value) {
    return I18n.t('%{percent} of students scored %{score}', {
      percent: this.percentText(value),
      score: this.percentText(score / 100),
    })
  }

  percentText(percent) {
    return I18n.n(Math.round((percent || 0) * 1000) / 10, {percentage: true})
  }
}
