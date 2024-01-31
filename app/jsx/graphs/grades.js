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
import {each, extend} from 'lodash'
import htmlEscape from 'html-escape'
import {useScope as useI18nScope} from '@canvas/i18n'
import Base from './base'
import Cover from './cover'
import ScaleByBins from './ScaleByBins'
import YAxis from './YAxis'

const I18n = useI18nScope('analytics_grades')

// #
// Grades visualizes the student's scores on assignments compared to the
// distribution of scores in the class. The distribution of each assignment is
// displayed as a "bar and whiskers" plot where the top whisker reaches to the
// max score, the bottom whisker to the min score, the box covers the first
// through third quartiles, and the median is stroked through the box. The
// student's score is superimposed on this as a colored dot. The distribution
// and dot are replaced by a faint placeholder for muted assignments in
// student view.
const defaultOptions = {
  // #
  // The color of the whiskers.
  whiskerColor: 'dimgray',

  // #
  // The color of the boxes.
  boxColor: 'lightgray',

  // #
  // The color of the median line.
  medianColor: 'dimgray',

  // #
  // The colors of the outer rings of value dots, by performance level.
  colorGood: 'green',
  colorFair: 'gold',
  colorPoor: 'red',

  // #
  // Max width of a bar, in pixels. (Overrides default from ScaleByBins)
  maxBarWidth: 30,
  gutterPercent: 1.0,
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
  }

  // #
  // Graph the assignments.
  graph(assignments) {
    if (!super.graph(...arguments)) return
    ;({assignments} = assignments)
    this.scaleToAssignments(assignments)
    this.yAxis.draw()
    this.drawXLabel(I18n.t('Assignments'))
    each(assignments, this.graphAssignment.bind(this))

    return this.finish()
  }

  // #
  // given an assignment, what's the max score possible/achieved so far?
  maxAssignmentScore(assignment) {
    if (assignment.pointsPossible != null) {
      return assignment.pointsPossible
    } else if (assignment.scoreDistribution != null) {
      return assignment.scoreDistribution.maxScore
    } else {
      return 0
    }
  }

  // #
  // Choose appropriate sizes for the graph elements based on number of
  // assignments and maximum score being graphed.
  scaleToAssignments(assignments) {
    // scale the x-axis for the number of bins
    this.scaleByBins(assignments.length, false)

    // top of max bar = @topMargin + @topPadding
    // base of bars = @topMargin + @height - @bottomPadding
    const maxScores = Array.from(assignments).map(a => this.maxAssignmentScore(a))

    let max = Math.max(...Array.from(maxScores || []))
    if (max == null || !(max > 0)) max = 1
    this.pointSpacing = (this.height - this.topPadding - this.bottomPadding) / max
    return (this.yAxis = new YAxis(this, {range: [0, max], title: I18n.t('Points')}))
  }

  // #
  // Graph a single assignment. Fat arrowed because it's called by _.each
  graphAssignment(assignment, i) {
    const x = this.binX(i)

    if (assignment.scoreDistribution != null) {
      this.drawWhisker(x, assignment)
      this.drawBox(x, assignment)
      this.drawMedian(x, assignment)
    }

    if (assignment.studentScore != null) {
      this.drawStudentScore(x, assignment)
    }

    return this.cover(x, assignment)
  }

  // #
  // Convert a score to a y-coordinate.
  valueY(score) {
    return this.base - score * this.pointSpacing
  }

  // #
  // Draw the whisker for an assignment's score distribution
  drawWhisker(x, assignment) {
    const whiskerTop = this.valueY(assignment.scoreDistribution.maxScore)
    const whiskerBottom = this.valueY(assignment.scoreDistribution.minScore)
    const whiskerHeight = whiskerBottom - whiskerTop
    const whisker = this.paper.rect(x, whiskerTop, 1, whiskerHeight)
    return whisker.attr({stroke: this.whiskerColor, fill: 'none'})
  }

  // #
  // Draw the box for an assignment's score distribution
  drawBox(x, assignment) {
    const boxTop = this.valueY(assignment.scoreDistribution.thirdQuartile)
    const boxBottom = this.valueY(assignment.scoreDistribution.firstQuartile)
    const boxHeight = boxBottom - boxTop
    const box = this.paper.rect(x - this.barWidth * 0.3, boxTop, this.barWidth * 0.6, boxHeight)
    return box.attr({stroke: this.boxColor, fill: this.boxColor})
  }

  // #
  // Draw the median of an assignment's score distribution
  drawMedian(x, assignment) {
    const medianY = this.valueY(assignment.scoreDistribution.median)
    const median = this.paper.rect(x - this.barWidth / 2, medianY, this.barWidth, 1)
    return median.attr({stroke: 'none', fill: this.medianColor})
  }

  // #
  // Draw the shape for the student's score in an assignment
  drawStudentScore(x, assignment) {
    const scoreY = this.valueY(assignment.studentScore)
    const attrs = this.scoreAttrs(assignment)
    attrs.color = 'white'
    attrs.outline = 1
    return this.drawShape(x, scoreY, this.barWidth / 4 + 2, attrs)
  }

  // #
  // Returns colors to use for the value dot of an assignment. If this is
  // being called, it's implied there is a student score for the assignment.
  scoreAttrs(assignment) {
    if (assignment.scoreDistribution != null) {
      if (assignment.studentScore >= assignment.scoreDistribution.median) {
        return {
          fill: this.colorGood,
          shape: 'circle',
        }
      } else if (assignment.studentScore >= assignment.scoreDistribution.firstQuartile) {
        return {
          fill: this.colorFair,
          shape: 'triangle',
        }
      } else {
        return {
          fill: this.colorPoor,
          shape: 'square',
        }
      }
    } else {
      return {
        fill: this.colorGood,
        shape: 'circle',
      }
    }
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
    let score
    let tooltip = htmlEscape(assignment.title)
    if (assignment.scoreDistribution != null) {
      tooltip += `<br/>${htmlEscape(
        I18n.t('High: %{score}', {score: I18n.n(assignment.scoreDistribution.maxScore)})
      )}`
      tooltip += `<br/>${htmlEscape(
        I18n.t('Median: %{score}', {score: I18n.n(assignment.scoreDistribution.median)})
      )}`
      tooltip += `<br/>${htmlEscape(
        I18n.t('Low: %{score}', {score: I18n.n(assignment.scoreDistribution.minScore)})
      )}`
      if (assignment.studentScore != null && assignment.pointsPossible != null) {
        score = `${I18n.n(assignment.studentScore)} / ${I18n.n(assignment.pointsPossible)}`
        tooltip += `<br/>${htmlEscape(I18n.t('Score: %{score}', {score}))}`
      } else if (assignment.studentScore != null) {
        tooltip += `<br/>${htmlEscape(
          I18n.t('Score: %{score}', {score: I18n.n(assignment.studentScore)})
        )}`
      } else if (assignment.pointsPossible != null) {
        tooltip += `<br/>${htmlEscape(
          I18n.t('Possible: %{score}', {score: I18n.n(assignment.pointsPossible)})
        )}`
      }
    } else if (assignment.studentScore != null && assignment.pointsPossible != null) {
      score = `${I18n.n(assignment.studentScore)} / ${I18n.n(assignment.pointsPossible)}`
      tooltip += `<br/>${htmlEscape(I18n.t('Score: %{score}', {score}))}`
    }
    if (assignment.muted) {
      tooltip += `<br/>${htmlEscape(I18n.t('(hidden)'))}`
    }

    return $.raw(tooltip)
  }
}
