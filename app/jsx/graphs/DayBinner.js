import Binner from '../graphs/Binner'
import helpers from '../helpers'
import I18n from '@canvas/i18n'

export default class DayBinner extends Binner {
  // #
  // Force date to preceding midnight.
  reduce(date) {
    return date.clone().clearTime()
  }

  // #
  // Count days. Assumes dates are reduced to midnight already.
  binsBetween(date1, date2) {
    return helpers.daysBetween(date1, date2)
  }

  tickChrome(tick, last) {
    // if there are fewer than 14 days, just label every day.
    // include the short month if the month has changed.
    if (this.binsBetween(this.startDate, this.endDate) < 14) {
      return {
        label:
          last == null || last.getMonth() !== tick.getMonth()
            ? I18n.l('date.formats.short', tick)
            : tick.getDate()
      }

      // otherwise, label the first of each month, including the year
      // if this has changed
    } else if (tick.getDate() === 1) {
      return {
        label:
          last == null || last.getYear() !== tick.getYear()
            ? I18n.l('date.formats.medium_month', tick)
            : I18n.l('date.formats.short_month', tick)
      }
    } else {
      return {}
    }
  }

  // #
  // Advance by one day.
  nextTick(tick) {
    return tick.clone().addDays(1)
  }
}
