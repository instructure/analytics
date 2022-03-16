import _ from 'underscore'
import Base from '../graphs/base'
import DayBinner from '../graphs/DayBinner'
import WeekBinner from '../graphs/WeekBinner'
import MonthBinner from '../graphs/MonthBinner'
import ScaleByBins from '../graphs/ScaleByBins'
import helpers from '../helpers'
import I18n from 'i18n!page_views'

// #
// Parent class for all graphs that have a date-aligned x-axis. Note: Left
// padding for this graph style is space from the frame to the start date's
// tick mark, not the leading graph element's edge. Similarly, right padding
// is space from the frame to the end date's tick, not the trailing graph
// element's edge. This is necessary to keep the date graphs aligned.
const defaultOptions = {
  // #
  // The date for the left end of the graph. Required.
  startDate: null,

  // #
  // The date for the right end of the graph. Required.
  endDate: null,

  // #
  // The size of the date tick marks, in pixels.
  tickSize: 5,

  // #
  // If any date is outside the bounds of the graph, we have a clipped date
  clippedDate: false
}

export default class DateAlignedGraph extends Base {
  // #
  // Takes an element and options, same as for Base. Recognizes the options
  // described above in addition to the options for Base.
  constructor(div, options) {
    super(...arguments)

    // mixin ScaleByBins functionality
    _.extend(this, ScaleByBins)

    // check for required options
    if (options.startDate == null) throw new Error('startDate is required')
    if (options.endDate == null) throw new Error('endDate is required')

    // copy in recognized options with defaults
    for (const key in defaultOptions) {
      const defaultValue = defaultOptions[key]
      this[key] = options[key] != null ? options[key] : defaultValue
    }

    this.initScale()
  }

  // #
  // Set up X-axis scale
  initScale() {
    const interior = this.width - this.leftPadding - this.rightPadding

    // mixin for the appropriate bin size
    // use a minimum of 10 pixels for bar width plus spacing before consolidating
    this.binner = new DayBinner(this.startDate, this.endDate)
    if (this.binner.count() * 10 > interior)
      this.binner = new WeekBinner(this.startDate, this.endDate)
    if (this.binner.count() * 10 > interior)
      this.binner = new MonthBinner(this.startDate, this.endDate)

    // scale the x-axis for the number of bins
    return this.scaleByBins(this.binner.count())
  }

  // #
  // Reset the graph chrome. Adds an x-axis with daily ticks and weekly (on
  // Mondays) labels.
  reset() {
    super.reset(...arguments)
    if (this.startDate) this.initScale()
    return this.drawDateAxis()
  }

  // #
  // Convert a date to a bin index.
  dateBin(date) {
    return this.binner.bin(date)
  }

  // #
  // Convert a date to its bin's x-coordinate.
  binnedDateX(date) {
    return this.binX(this.dateBin(date))
  }

  // #
  // Given a datetime, return the floor and ceil as calculated by the binner
  dateExtent(datetime) {
    const floor = this.binner.reduce(datetime)
    return [floor, this.binner.nextTick(floor)]
  }

  // #
  // Given a datetime and a datetime range, return a number from 0.0 to 1.0
  dateFraction(datetime, floorDate, ceilDate) {
    const deltaSeconds = datetime.getTime() - floorDate.getTime()
    const totalSeconds = ceilDate.getTime() - floorDate.getTime()
    return deltaSeconds / totalSeconds
  }

  // #
  // Convert a date to an intra-bin x-coordinate.
  dateX(datetime) {
    const minX = this.leftMargin
    const maxX = this.leftMargin + this.width

    const [floorDate, ceilDate] = this.dateExtent(datetime)
    const floorX = this.binnedDateX(floorDate)
    const ceilX = this.binnedDateX(ceilDate)

    const fraction = this.dateFraction(datetime, floorDate, ceilDate)

    if (datetime.getTime() < this.startDate.getTime()) {
      // out of range, left
      this.clippedDate = true
      return minX
    } else if (datetime.getTime() > this.endDate.getTime()) {
      // out of range, right
      this.clippedDate = true
      return maxX
    } else {
      // in range
      return floorX + fraction * (ceilX - floorX)
    }
  }

  // #
  // Draw a guide along the x-axis. Each day gets a pair of ticks; one from
  // the top of the frame, the other from the bottom. The ticks are replaced
  // by a full vertical grid line on Mondays, accompanied by a label.
  drawDateAxis() {
    // skip if we haven't set start/end dates yet (@reset will be called by
    // Base's constructor before we set startDate or endDate)
    if (this.startDate == null || this.endDate == null) return
    return this.binner.eachTick((tick, chrome) => {
      const x = this.binnedDateX(tick)
      if (chrome && chrome.label) return this.dateLabel(x, this.topMargin + this.height, chrome.label)
    })
  }

  // #
  // Draw label text at (x, y).
  dateLabel(x, y, text) {
    const label = this.paper.text(x, y, text)
    return label.attr({fill: this.frameColor})
  }

  // #
  // Get date text for a bin
  binDateText(bin) {
    const lastDay = this.binner.nextTick(bin.date).addDays(-1)
    const daysBetween = helpers.daysBetween(bin.date, lastDay)
    if (daysBetween < 1) {
      // single-day bucket: label the date
      return I18n.l('date.formats.medium', bin.date)
    } else if (daysBetween < 7) {
      // one-week bucket: label the start and end days; include the year only with the end day unless they're different
      return I18n.t('%{start_date} - %{end_date}', {
        start_date: I18n.l(
          bin.date.getFullYear() === lastDay.getFullYear()
            ? 'date.formats.short'
            : 'date.formats.medium',
          bin.date
        ),
        end_date: I18n.l('date.formats.medium', lastDay)
      })
    } else {
      // one-month bucket; label the month and year
      return I18n.l('date.formats.medium_month', bin.date)
    }
  }
}
