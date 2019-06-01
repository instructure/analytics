import Binner from '../graphs/Binner'

export default class MonthBinner extends Binner {
  // #
  // Force date to preceding first of month (midnight).
  reduce(date) {
    date = date.clone().clearTime()
    if (date.getDate() > 1) date.setDate(1)
    return date
  }

  // #
  // Count months. Assumes dates are reduced to firsts of months already.
  binsBetween(date1, date2) {
    return date2.getMonth() - date1.getMonth() + (date2.getFullYear() - date1.getFullYear()) * 12
  }

  // #
  // Label each year on January's tick.
  tickChrome(tick, last) {
    if (tick.getMonth() !== 0) {
      return {}
    }

    return {label: tick.getFullYear()}
  }

  // #
  // Advance by one month
  nextTick(tick) {
    return tick.clone().addMonths(1)
  }
}
