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

import $ from 'jquery'
import {each, reject, extend} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'
import Base from './base'
import Cover from './cover'
import ScaleByBins from './ScaleByBins'
import YAxis from './YAxis'

const I18n = useI18nScope('finishing_assignments')

// #
// FinishingAssignmentCourse visualizes the proportion of students that are
// turning in assignments on time, late, or not at all. Each assignment gets
// one bar, which is shown as layered percentiles. The layers are, from bottom
// to top:
//
//   * Percent of students that turned the assignment in on time.
//   * Percent of students that turned the assignment in late (if past due).
//   * Percent of students that missed the assignment (if past due).
//
// For assignments that are past due, these three layers will add up to 100%.
// For assignments that are not yet due or which have no due date, only the
// first layer will be included and can be read as the percentage of students
// that have completed the assignment.

const defaultOptions = {
  // #
  // The color of the bottom layer (on time).
  onTimeColor: 'darkgreen',

  // #
  // The color of the middle layer (past due, turned in late).
  lateColor: 'darkyellow',

  // #
  // The color of the top layer (past due, missing).
  missingColor: 'red',
}

export default class Grades extends Base {
  // #
  // Takes an element id and options, same as for Base. Recognizes the options
  // described above in addition to the options for Base.
  constructor(div, options) {
    super(...arguments)
    this.graphAssignment = this.graphAssignment.bind(this)

    // mixin ScaleByBins functionality
    extend(this, ScaleByBins)

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    this.base = this.topMargin + this.height - this.bottomPadding

    // top of max bar = @topMargin + @topPadding
    // base of bars = @topMargin + @height - @bottomPadding
    // grid lines every 10%
    this.innerHeight = this.height - this.topPadding - this.bottomPadding
    this.yAxis = new YAxis(this, {range: [0, 1], style: 'percent'})
  }

  reset() {
    super.reset(...arguments)
    return this.yAxis != null ? this.yAxis.draw() : undefined
  }

  // #
  // Graph the assignments.
  graph(assignments) {
    if (!super.graph(...arguments)) return

    assignments = reject(assignments.assignments, a => a.non_digital_submission)
    this.scaleByBins(assignments.length, false)
    this.drawXLabel(I18n.t('Assignments'))
    each(assignments, this.graphAssignment.bind(this))

    return this.finish()
  }

  // #
  // Graph a single assignment. Fat arrowed because it's called by _.each
  graphAssignment(assignment, i) {
    let breakdown
    const x = this.binX(i)
    if ((breakdown = assignment.tardinessBreakdown) != null) {
      let base = 0
      base = this.drawLayer(x, base, breakdown.onTime, this.onTimeColor, 0, 15)
      base = this.drawLayer(x, base, breakdown.late, this.lateColor, 0, 0)
      base = this.drawLayer(x, base, breakdown.missing, this.missingColor, 15, 0)
    }

    return this.cover(x, assignment)
  }

  // #
  // Draws the next layer at x, starting at base% and increasing by delta% in
  // color.
  drawLayer(x, base, delta, color, top_radius, bottom_radius) {
    if (delta > 0) {
      const summit = base + delta
      const bottom = this.valueY(base)
      const top = this.valueY(summit)
      const height = bottom - top
      const box = this.roundedRect(
        x - this.barWidth / 2,
        top,
        this.barWidth,
        height,
        top_radius,
        bottom_radius
      )
      box.attr({stroke: 'white', fill: color, 'stroke-width': 2})
      return summit
    } else {
      return base
    }
  }

  // #
  // Draw a rectangle with independent top/bottom rounding radii
  roundedRect(x, y, w, h, tr, br) {
    // clip radius to fit within bar
    const sm = Math.min(w, h)
    tr = Math.min(tr, sm / 2)
    br = Math.min(br, sm / 2)
    // draw bar
    const path = ['M', x + tr, y]
    path.push('l', w - tr * 2, 0) // top
    path.push('q', tr, 0, tr, tr) // tr
    path.push('l', 0, h - tr - br) // r
    path.push('q', 0, br, -br, br) // br
    path.push('l', -(w - br * 2), 0) // b
    path.push('q', -br, 0, -br, -br) // bl
    path.push('l', 0, -(h - br - tr)) // l
    path.push('q', 0, -tr, tr, -tr) // tl
    path.push('z')
    return this.paper.path(path)
  }

  // #
  // Convert a score to a y-coordinate.
  valueY(percent) {
    return this.base - percent * this.innerHeight
  }

  // #
  // Create a tooltip for the assignment.
  cover(x, assignment) {
    return new Cover(this, {
      region: this.paper.rect(
        x - this.coverWidth / 2,
        this.topMargin,
        this.coverWidth,
        this.height
      ),
      classes: `assignment_${assignment.id}`,
      tooltip: {
        contents: this.tooltip(assignment),
        x,
        y: this.base,
        direction: 'down',
      },
    })
  }

  // #
  // Build the text for the assignment's tooltip.
  tooltip(assignment) {
    let breakdown
    let tooltip = htmlEscape(assignment.title)
    if (assignment.multipleDueDates) {
      tooltip += `<br/>${htmlEscape(I18n.t('Due: Multiple Dates'))}`
    } else if (assignment.dueAt != null) {
      tooltip += `<br/>${htmlEscape(
        I18n.t('Due: %{date}', {date: I18n.l('date.formats.medium', assignment.dueAt)})
      )}`
    }
    if ((breakdown = assignment.tardinessBreakdown) != null) {
      if (breakdown.missing > 0) {
        tooltip += `<br/>${htmlEscape(
          I18n.t('Missing: %{percent}', {percent: this.percentText(breakdown.missing)})
        )}`
      }
      if (breakdown.late > 0) {
        tooltip += `<br/>${htmlEscape(
          I18n.t('Late: %{percent}', {percent: this.percentText(breakdown.late)})
        )}`
      }
      if (breakdown.onTime > 0) {
        tooltip += `<br/>${htmlEscape(
          I18n.t('On Time: %{percent}', {percent: this.percentText(breakdown.onTime)})
        )}`
      }
    }
    return $.raw(tooltip)
  }

  percentText(percent) {
    return `${String(Math.round(percent * 1000) / 10)}%`
  }
}
