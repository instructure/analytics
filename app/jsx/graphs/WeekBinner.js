import Binner from '../graphs/Binner'
import helpers from '../helpers'
import I18n from '@canvas/i18n'

export default class WeekBinner extends Binner {
  // #
  // Force date to preceding Monday midnight.
  reduce(date) {
    date = date.clone().clearTime()
    if (date.getDay() === 0) {
      date.addDays(-6)
    } else if (date.getDay() !== 1) {
      date.addDays(1 - date.getDay())
    }
    return date
  }

  // #
  // Count weeks. Assumes dates are reduced to mondays already.
  binsBetween(date1, date2) {
    return helpers.daysBetween(date1, date2) / 7
  }

  // #
  // Label the first tick in a month. If the year has changed,
  // include it in the label
  tickChrome(tick, last) {
    if (!(tick.getDate() <= 7)) {
      return
    }

    return {
      label:
        last == null || tick.getFullYear() !== last.getFullYear()
          ? I18n.l('date.formats.medium_month', tick)
          : I18n.l('date.formats.short_month', tick)
    }
  }

  // #
  // Advance by one week
  nextTick(tick) {
    return tick.clone().addWeeks(1)
  }
}
