define [
  'analytics/compiled/graphs/Binner'
  'analytics/compiled/helpers'
  'i18nObj'
], (Binner, helpers, I18n) ->

  class MonthBinner extends Binner
    ##
    # Force date to preceding first of month (midnight).
    reduce: (date) ->
      date = date.clone().clearTime()
      date.setDate 1 if date.getDate() > 1
      date

    ##
    # Count months. Assumes dates are reduced to firsts of months already.
    binsBetween: (date1, date2) ->
      (date2.getMonth() - date1.getMonth()) + (date2.getFullYear() - date1.getFullYear()) * 12

    ##
    # Label each year on January's tick.
    tickChrome: (tick, last) ->
      return {} unless tick.getMonth() is 0

      label: tick.getFullYear()

    ##
    # Advance by one month
    nextTick: (tick) ->
      tick.clone().addMonths 1
