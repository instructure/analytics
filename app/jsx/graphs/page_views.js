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

import {extend, each} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from 'html-escape'
import DateAlignedGraph from './DateAlignedGraph'
import Cover from './cover'
import YAxis from './YAxis'

const I18n = useI18nScope('page_views')

// #
// PageViews visualizes the student's activity within the course. Each bar
// represents one time span (typically one day, but if there are a large
// amount of days, it may instead by one week per bin). The height of the bar
// is the number of course pages viewed in that time span. The bar is blue on
// if there were any participations in that time span (took a quiz, posted a
// discussion reply, etc.) and gray otherwise.

const defaultOptions = {
  // #
  // The fill color of the bars for bins without participations.
  barColor: 'lightgray',

  // #
  // The fill color of the bars for bins with participations.
  participationColor: 'lightblue',
}

export default class PageViews extends DateAlignedGraph {
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

    // base of bars = @topMargin + @height - @bottomPadding
    this.base = this.topMargin + this.height - this.bottomPadding
  }

  // #
  // Combine bins by an index reduction.
  reduceBins(sourceBins) {
    const bins = []
    const binMap = {}
    each(sourceBins, bin => {
      if (bin.date.between(this.startDate, this.endDate)) {
        const index = this.binner.reduce(bin.date)
        if (binMap[index]) {
          binMap[index].views += bin.views
          return (binMap[index].participations += bin.participations)
        } else {
          binMap[index] = extend({}, bin)
          binMap[index].date = index
          return bins.push(binMap[index])
        }
      }
    })
    return bins
  }

  // #
  // Graph the data.
  graph(participation) {
    if (!super.graph(...arguments)) return

    // reduce the bins to the appropriate time scale
    const bins = this.reduceBins(participation.bins)
    this.scaleToData(bins)
    this.yAxis.draw()
    each(bins, this.graphBin.bind(this))

    return this.finish()
  }

  // #
  // Choose appropriate sizes for the graph elements based on maximum value
  // being graphed.
  scaleToData(bins) {
    // top of max bar = @topMargin + @topPadding
    const views = Array.from(bins).map(bin => bin.views)
    let max = Math.max(...Array.from(views || []))
    if (max == null || !(max > 0)) max = 1
    this.countSpacing = (this.height - this.topPadding - this.bottomPadding) / max
    return (this.yAxis = new YAxis(this, {range: [0, max], title: I18n.t('Page Views')}))
  }

  // #
  // Graph a single bin. Fat arrowed because it's called by _.each
  graphBin(bin) {
    const x = this.binnedDateX(bin.date)
    const y = this.valueY(bin.views)
    const bar = this.paper.rect(x - this.barWidth / 2, y, this.barWidth, this.base - y)
    bar.attr(this.binColors(bin))
    return this.cover(x, bin)
  }

  // #
  // Calculate the height of a bin, in pixels.
  valueY(j) {
    return this.base - j * this.countSpacing
  }

  // #
  // Determine the colors to use for a bin.
  binColors(bin) {
    if (bin.participations > 0) {
      return {
        stroke: 'white',
        fill: this.participationColor,
      }
    } else {
      return {
        stroke: 'white',
        fill: this.barColor,
      }
    }
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
      classes: I18n.l('date.formats.default', bin.date),
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
    let count
    let tooltip = htmlEscape(this.binDateText(bin))
    if (bin.participations > 0) {
      count = bin.participations
      tooltip += `<br/>${htmlEscape(
        I18n.t({one: '1 participation', other: '%{count} participations'}, {count})
      )}`
    }
    if (bin.views > 0) {
      count = bin.views
      tooltip += `<br/>${htmlEscape(
        I18n.t({one: '1 page view', other: '%{count} page views'}, {count})
      )}`
    }
    return $.raw(tooltip)
  }
}
