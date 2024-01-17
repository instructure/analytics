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

import {extend, maxBy, sortBy, each} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'
import Base from './base'
import Cover from './cover'
import ScaleByBins from './ScaleByBins'
import YAxis from './YAxis'

const I18n = useI18nScope('page_views')

// #
// CategorizedPageViews visualizes the student's activity within the course by
// type of action rather than date. Each bar represents one category. The
// height of the bar is the number of course pages viewed in that time span.
const defaultOptions = {
  // #
  // The fill color of the bars.
  barColor: 'lightblue',

  // #
  // The stroke color of the bars.
  strokeColor: '#b1c6d8',

  // #
  // The size of the tick marks, in pixels.
  tickSize: 5,

  // #
  // What to sort by ("views", "category")
  sortBy: 'category',
}

function internationalizeBin(bin) {
  switch (bin.category) {
    case 'announcements':
      bin.category = I18n.t('announcements')
      break
    case 'assignments':
      bin.category = I18n.t('assignments')
      break
    case 'collaborations':
      bin.category = I18n.t('collaborations')
      break
    case 'conferences':
      bin.category = I18n.t('conferences')
      break
    case 'discussions':
      bin.category = I18n.t('discussions')
      break
    case 'files':
      bin.category = I18n.t('files')
      break
    case 'general':
      bin.category = I18n.t('general')
      break
    case 'grades':
      bin.category = I18n.t('grades')
      break
    case 'groups':
      bin.category = I18n.t('groups')
      break
    case 'modules':
      bin.category = I18n.t('modules')
      break
    case 'other':
      bin.category = I18n.t('other')
      break
    case 'pages':
      bin.category = I18n.t('pages')
      break
    case 'quizzes':
      bin.category = I18n.t('quizzes')
      break
  }
}

export default class CategorizedPageViews extends Base {
  // #
  // Takes an element and options, same as for Base. Recognizes the options
  // described above in addition to the options for Base.
  constructor(div, options) {
    super(...arguments)
    this.graphBin = this.graphBin.bind(this)
    this.valueY = this.valueY.bind(this)

    // mixin ScaleByBins functionality
    extend(this, ScaleByBins)

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    // base of bars = @topmargin + @height - @bottompadding
    this.base = this.topMargin + this.height - this.bottomPadding
  }

  // #
  // Graph the data.
  graph(participation) {
    if (!super.graph(...arguments)) {
      return
    }

    // reduce the bins to the appropriate time scale
    let bins = participation.categoryBins

    bins.forEach(bin => {
      internationalizeBin(bin)
    })

    if (this.sortBy === 'views' && bins.length > 0) {
      const maxViews = maxBy(bins, b => b.views).views
      bins = sortBy(bins, b => [maxViews - b.views, b.category])
    }

    this.scaleToData(bins)
    this.drawXAxis(bins)
    this.yAxis.draw()
    each(bins, this.graphBin.bind(this))
    return this.finish()
  }

  // #
  // Choose appropriate sizes for the graph elements based on maximum value
  // being graphed.
  scaleToData(bins) {
    // scale the x-axis for the number of bins
    this.scaleByBins(bins.length, false)

    // top of max bar = @topMargin + @topPadding
    const views = Array.from(bins).map(bin => bin.views)
    let max = Math.max(...Array.from(views || []))
    if (max == null || !(max > 0)) {
      max = 1
    }
    this.countSpacing = (this.height - this.topPadding - this.bottomPadding) / max
    return (this.yAxis = new YAxis(this, {range: [0, max], title: I18n.t('Page Views')}))
  }

  // #
  // Draw a guide along the x-axis. Each category bin gets a pair of ticks;
  // one from the top of the frame, the other from the bottom. Each tick is
  // labeled with the bin category.
  drawXAxis(bins) {
    return (() => {
      const result = []
      for (const i in bins) {
        const bin = bins[i]
        const x = this.binX(i)
        const y = this.topMargin + this.height + (i % 2) * 10
        result.push(this.labelBin(x, y, bin.category))
      }
      return result
    })()
  }

  // #
  // Draw label text at (x, y).
  labelBin(x, y, text) {
    const label = this.paper.text(x, y, text)
    return label.attr({fill: this.frameColor})
  }

  // #
  // Graph a single bin. Fat arrowed because it's called by _.each
  graphBin(bin, i) {
    const x = this.binX(i)
    const y = this.valueY(bin.views)
    const bar = this.paper.rect(x - this.barWidth / 2, y, this.barWidth, this.base - y)
    bar.attr({stroke: this.strokeColor, fill: this.barColor})
    return this.cover(x, bin)
  }

  // #
  // Calculate the y-coordinate, in pixels, for a value.
  valueY(value) {
    return this.base - value * this.countSpacing
  }

  // #
  // Create a tooltip for the bin.
  cover(x, bin) {
    return new Cover(this, {
      region: this.paper.rect(
        x - this.coverWidth / 2,
        this.topMargin,
        this.coverWidth,
        this.height
      ),
      classes: bin.category,
      tooltip: {
        contents: this.tooltip(bin),
        x,
        y: this.base,
        direction: 'down',
      },
    })
  }

  // #
  // Build the text for the bin's tooltip.
  tooltip(bin) {
    const count = bin.views
    return $.raw(
      `${htmlEscape(bin.category)}<br/>${htmlEscape(
        I18n.t({one: '1 page view', other: '%{count} page views'}, {count})
      )}`
    )
  }
}
