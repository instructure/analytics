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

import {reject, each} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'
import DateAlignedGraph from './DateAlignedGraph'
import Cover from './cover'

const I18n = useI18nScope('time')

// #
// AssignmentTardiness visualizes the student's ability to turn in assignments
// on time. It displays one assignment per row, with the x-axis aligned to
// time. An assignment is displayed in its row with a diamond on the due date
// (or at the end of the row if there is no due date) and a bar representing
// the time between the student's submission and the due date.
const defaultOptions = {
  // #
  // The height of the assignment lanes, in pixels
  laneHeight: 16,

  // #
  // The height of the submission bars, in pixels.
  barHeight: 4,

  // #
  // The height of the due date diamonds, in pixels. Defaults to laneHeight
  // if unset.
  shapeHeight: null,

  // #
  // The size of the vertical gutter between elements as a percent of the
  // height of those elements.
  gutterPercent: 0.25,

  // #
  // Color for on time assignments.
  colorOnTime: 'green',

  // #
  // Color for late assignments.
  colorLate: 'gold',

  // #
  // Color for missing assignments.
  colorMissing: 'red',

  // #
  // Color for undated assignments.
  colorUndated: 'darkgray',

  // #
  // Color for unfilled shapes
  colorEmpty: 'white',

  // #
  // Message when dates fall outside bounds of graph
  clippedWarningLabel: I18n.t(
    'Note: some items fall outside the start and/or end dates of the course'
  ),
}

export default class AssignmentTardiness extends DateAlignedGraph {
  // #
  // Takes an element and options, same as for DateAlignedGraph. Recognizes
  // the options described above in addition to the options for
  // DateAlignedGraph.
  constructor(div, options) {
    super(...arguments)
    this.graph = this.graph.bind(this)

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    if (this.shapeHeight == null) this.shapeHeight = this.laneHeight
    this.gutterHeight = this.gutterPercent * this.laneHeight
    this.barSpacing = this.laneHeight + this.gutterHeight

    // middle of first bar
    this.y0 = this.topMargin + this.topPadding + this.shapeHeight / 2
  }

  // #
  // Graph the assignments.
  graph(assignments) {
    if (!super.graph(...arguments)) return

    assignments = reject(assignments.assignments, a => a.non_digital_submission)
    if (assignments != null && assignments.length > 0) {
      this.scaleToAssignments(assignments)
      if (this.gridColor) {
        this.drawGrid(assignments)
      }
      this.drawYLabel(I18n.t('Assignments'))
      each(assignments, this.graphAssignment.bind(this))

      if (this.clippedDate) {
        const label = this.clippedWarningLabel
        this.drawWarning(label)
      }
    }

    return this.finish()
  }

  // #
  // Resize the graph vertically to accomodate the number of assigments.
  scaleToAssignments(assignments) {
    return this.resize({
      height:
        this.topPadding +
        (assignments.length - 1) * this.barSpacing +
        this.shapeHeight +
        this.laneHeight / 2 +
        this.bottomPadding,
    })
  }

  // #
  // Draws the gutters between the assignments.
  drawGrid(assignments) {
    return __range__(0, assignments.length - 1, true).map(i => this.drawGridLine(this.gridY(i)))
  }

  drawGridLine(y) {
    const gridline = this.paper.path(['M', this.leftMargin, y, 'l', this.width, 0])
    return gridline.attr({stroke: this.gridColor})
  }

  gridY(index) {
    return this.indexY(index)
  }

  // #
  // Graph a single assignment. Fat arrowed because it's called by _.each
  graphAssignment(assignment, index) {
    const dueX = this.dueX(assignment)
    const submittedX = this.submittedX(assignment)
    const y = this.indexY(index)
    const attrs = this.shape_attrs(assignment)
    if (submittedX != null && submittedX !== dueX) {
      this.drawSubmittedBar(dueX, submittedX, y, attrs.color)
    }
    this.drawShape(dueX, y, this.shapeHeight / 2, attrs)
    return this.cover(dueX, y, assignment)
  }

  // #
  // Determine the colors to use for an assignment.
  shape_attrs(assignment) {
    if (assignment.dueAt == null) {
      // no due date
      if (assignment.submittedAt != null) {
        // if it's submitted, it's "on time"
        return {
          color: this.colorOnTime,
          shape: 'circle',
          fill: this.colorOnTime,
        }
      } else {
        // otherwise it's "future"
        return {
          color: this.colorUndated,
          shape: 'circle',
          fill: this.colorEmpty,
        }
      }
    } else if (assignment.onTime === true) {
      // has due date, turned in on time
      return {
        color: this.colorOnTime,
        shape: 'circle',
        fill: this.colorOnTime,
      }
    } else if (assignment.onTime === false) {
      // has due date, turned in late
      return {
        color: this.colorLate,
        shape: 'triangle',
        fill: this.colorLate,
      }
    } else if (assignment.dueAt > new Date()) {
      // due in the future, not turned in
      return {
        color: this.colorUndated,
        shape: 'circle',
        fill: this.colorEmpty,
      }
    } else {
      // due in the past, not turned in
      return {
        color: this.colorMissing,
        shape: 'square',
        fill: this.colorMissing,
      }
    }
  }

  // #
  // Convert an assignment's due date to an x-coordinate. If no due date, use
  // submitted at. If no due date and not submitted, use the end date.
  dueX(assignment) {
    let left
    return this.dateX(
      (left = assignment.dueAt != null ? assignment.dueAt : assignment.submittedAt) != null
        ? left
        : this.endDate
    )
  }

  // #
  // Convert an assignment's submitted at to an x-coordinate.
  submittedX(assignment) {
    if (assignment.submittedAt != null) {
      return this.dateX(assignment.submittedAt)
    } else {
      return null
    }
  }

  // #
  // Convert an assignment index to a y-coordinate.
  indexY(index) {
    return this.y0 + index * this.barSpacing
  }

  // #
  // Draw the bar representing the difference between submitted at and due
  // date.
  drawSubmittedBar(x1, x2, y, color) {
    const [left, right] = Array.from(x1 < x2 ? [x1, x2] : [x2, x1])
    const bar = this.paper.rect(left, y - this.barHeight / 2, right - left, this.barHeight)
    return bar.attr({fill: color, stroke: color})
  }

  // #
  // Create a tooltip for the assignment.
  cover(x, y, assignment) {
    return new Cover(this, {
      region: this.paper.rect(
        this.leftMargin,
        y - this.barSpacing / 2,
        this.width,
        this.barSpacing
      ),
      classes: `assignment_${assignment.id}`,
      tooltip: {
        contents: this.tooltip(assignment),
        x,
        y: y + this.shapeHeight / 2,
        direction: 'down',
      },
    })
  }

  // #
  // Build the text for the assignment's tooltip.
  tooltip(assignment) {
    let tooltip = htmlEscape(assignment.title)

    if (assignment.dueAt != null) {
      const dueAtString = I18n.t('due_date', '%{date} by %{time}', {
        date: I18n.l('date.formats.medium', assignment.dueAt),
        time: I18n.l('time.formats.tiny', assignment.dueAt),
      })
      tooltip += `<br/>${htmlEscape(I18n.t('Due: %{dateTime}', {dateTime: dueAtString}))}`
    } else {
      tooltip += `<br/>${htmlEscape(I18n.t('(no due date)'))}`
    }
    if (assignment.submittedAt != null) {
      const submittedAtString = I18n.t('event', '%{date} at %{time}', {
        date: I18n.l('date.formats.medium', assignment.submittedAt),
        time: I18n.l('time.formats.tiny', assignment.submittedAt),
      })
      tooltip += `<br/>${htmlEscape(
        I18n.t('Submitted: %{dateTime}', {dateTime: submittedAtString})
      )}`
    }
    if (assignment.muted) {
      tooltip += `<br/>${htmlEscape(I18n.t('Score: (hidden)'))}`
    } else if (assignment.studentScore != null) {
      tooltip += `<br/>${htmlEscape(
        I18n.t('Score: %{score}', {score: I18n.n(assignment.studentScore)})
      )}`
    }
    return $.raw(tooltip)
  }
}

function __range__(left, right, inclusive) {
  const range = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
