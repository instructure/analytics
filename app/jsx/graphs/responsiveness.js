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

import {filter, each} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'
import DateAlignedGraph from './DateAlignedGraph'
import Cover from './cover'

const I18n = useI18nScope('responsiveness')

// #
// Responsiveness visualizes the student's communication frequency with the
// instructors of the class. A message icon represents a day in which the
// student sent a message to an instructor or an instructor sent a message to
// the student. Messages from the student are in the top track and messages
// from instructors are in the bottom track.

const defaultOptions = {
  // #
  // The size of the vertical gutter between the two tracks, in pixels.
  gutterHeight: 10,

  // #
  // The width of the message icon, in pixels.
  markerWidth: 30,

  // #
  // The distance, in pixels, from the carat to the right edge of the marker.
  caratOffset: 7,

  // #
  // The size of the carat, in pixels.
  caratSize: 3,

  // #
  // The fill color of the icons in the student track.
  studentColor: 'lightblue',

  // #
  // The fill color of the icons in the instructor track.
  instructorColor: 'lightgreen',
}

export default class Responsiveness extends DateAlignedGraph {
  // #
  // Takes an element and options, same as for DateAlignedGraph. Recognizes
  // the options described above in addition to the options for
  // DateAlignedGraph.
  constructor(div, options) {
    super(...arguments)
    this.graphBin = this.graphBin.bind(this)

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    // placement of tracks of markers
    this.markerHeight =
      (this.height - this.topPadding - this.bottomPadding - this.gutterHeight) / 2 -
      this.verticalMargin
    this.studentTrack = this.topMargin + this.topPadding
    this.instructorTrack = this.studentTrack + this.markerHeight + this.gutterHeight
    this.center = this.instructorTrack - this.gutterHeight / 2
  }

  reset() {
    super.reset(...arguments)

    // label the tracks
    this.paper.text(this.leftMargin - 10, this.topMargin, I18n.t('student')).attr({
      fill: this.frameColor,
      transform: 'r-90',
      'text-anchor': 'end',
    })

    return this.paper
      .text(
        this.leftMargin - 10,
        this.topMargin + this.height - this.bottomPadding,
        I18n.t('instructors')
      )
      .attr({
        fill: this.frameColor,
        transform: 'r-90',
        'text-anchor': 'start',
      })
  }

  // #
  // Graph the data.
  graph(messaging) {
    if (!super.graph(...arguments)) return

    const bins = filter(
      messaging.bins,
      bin => bin.date.between(this.startDate, this.endDate) && bin.messages > 0
    )

    each(bins, this.graphBin.bind(this))

    return this.finish()
  }

  // #
  // Graph a single bin; i.e. a (day, track) pair. Fat arrowed because
  // it's called by _.each
  graphBin(bin) {
    switch (bin.track) {
      case 'student':
        return this.graphStudentBin(bin)
      case 'instructor':
        return this.graphInstructorBin(bin)
    }
  }

  // #
  // Place a student marker for the given day.
  graphStudentBin(bin) {
    const icon = this.paper.path(this.studentPath(bin.date))
    icon.attr({stroke: 'white', fill: this.studentColor})
    return this.cover(bin.date, this.studentTrack, bin.messages)
  }

  // #
  // Place an instructor marker for the given day.
  graphInstructorBin(bin) {
    const icon = this.paper.path(this.instructorPath(bin.date))
    icon.attr({stroke: 'white', fill: this.instructorColor})
    return this.cover(bin.date, this.instructorTrack, bin.messages)
  }

  // #
  // Calculate the marker's bounding box (excluding carat) for a given day and
  // track.
  markerBox(date, track) {
    const x = this.binnedDateX(date)
    return {
      carat: x,
      right: x + this.caratOffset,
      left: x + this.caratOffset - this.markerWidth,
      top: track,
      bottom: track + this.markerHeight,
    }
  }

  // #
  // Calculate the corner centers for a given bounding box.
  markerCorners(box) {
    return {
      left: box.left + 3,
      right: box.right - 3,
      top: box.top + 3,
      bottom: box.bottom - 3,
    }
  }

  // #
  // Calculate the carat values for a given bounding box and carat direction.
  markerCarat(box, direction) {
    return {
      left: box.carat - this.caratSize,
      right: box.carat,
      tip: (() => {
        switch (direction) {
          case 'up':
            return box.top - this.caratSize
          case 'down':
            return box.bottom + this.caratSize
        }
      })(),
    }
  }

  // #
  // Build an SVG path for a student marker on the given day.
  studentPath(date) {
    const box = this.markerBox(date, this.studentTrack)
    const corners = this.markerCorners(box)
    const carat = this.markerCarat(box, 'down')

    return [
      'M',
      corners.left,
      box.top, // start at the top-left
      'L',
      corners.right,
      box.top, // across the top
      'A',
      3,
      3,
      0,
      0,
      1,
      box.right,
      corners.top, // around the top-right corner
      'L',
      box.right,
      corners.bottom, // down the right side
      'A',
      3,
      3,
      0,
      0,
      1,
      corners.right,
      box.bottom, // around the bottom-right corner
      'L',
      carat.right,
      box.bottom, // across the bottom to the carat
      carat.right,
      carat.tip, // down to the carat tip
      carat.left,
      box.bottom, // back up to the bottom
      corners.left,
      box.bottom, // across the rest of the bottom
      'A',
      3,
      3,
      0,
      0,
      1,
      box.left,
      corners.bottom, // around the bottom-left corner
      'L',
      box.left,
      corners.top, // up the left side
      'A',
      3,
      3,
      0,
      0,
      1,
      corners.left,
      box.top, // around the top-left corner
      'z',
    ] // done
  }

  // #
  // Build an SVG path for an instructor marker on the given day.
  instructorPath(date) {
    const box = this.markerBox(date, this.instructorTrack)
    const corners = this.markerCorners(box)
    const carat = this.markerCarat(box, 'up')

    return [
      'M',
      corners.left,
      box.top, // start at the top-left
      'L',
      carat.left,
      box.top, // across the top to the carat
      carat.right,
      carat.tip, // up to the carat tip
      carat.right,
      box.top, // back down to the top
      corners.right,
      box.top, // across the rest of the top
      'A',
      3,
      3,
      0,
      0,
      1,
      box.right,
      corners.top, // around the top-right corner
      'L',
      box.right,
      corners.bottom, // down the right side
      'A',
      3,
      3,
      0,
      0,
      1,
      corners.right,
      box.bottom, // around the bottom-right corner
      'L',
      corners.left,
      box.bottom, // across the bottom
      'A',
      3,
      3,
      0,
      0,
      1,
      box.left,
      corners.bottom, // around the bottom-left corner
      'L',
      box.left,
      corners.top, // up the left side
      'A',
      3,
      3,
      0,
      0,
      1,
      corners.left,
      box.top, // around the top-left corner
      'z',
    ] // done
  }

  // #
  // Create a tooltip for a day and track bin.
  cover(date, track, value) {
    const box = this.markerBox(date)
    const [top, bottom, direction, klass] = Array.from(
      (() => {
        switch (track) {
          case this.studentTrack:
            return [this.topMargin, this.center, 'down', 'student']
          case this.instructorTrack:
            return [this.center, this.topMargin + this.height, 'up', 'instructor']
        }
      })()
    )
    return new Cover(this, {
      region: this.paper.rect(box.left, top, this.markerWidth, bottom - top),
      classes: [klass, I18n.l('date.formats.default', date)],
      tooltip: {
        contents: this.tooltip(date, value),
        x: box.carat,
        y: this.center,
        direction,
      },
    })
  }

  // #
  // Build the text for a bin's tooltip.
  tooltip(date, value) {
    return $.raw(
      `${htmlEscape(I18n.l('date.formats.medium', date))}<br/>${htmlEscape(
        I18n.t({one: '1 message', other: '%{count} messages'}, {count: value})
      )}`
    )
  }
}
