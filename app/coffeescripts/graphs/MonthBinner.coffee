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
    # Include tick chrome on January of each year. Draw a grid line and bottom
    # label on each of those ticks, with the year as the bottom label. Never
    # draw a top label.
    tickChrome: (tick, last) ->
      return {} unless tick.getMonth() is 0

      grid: true
      bottomLabel: tick.getFullYear()
      topLabel: null

    ##
    # Advance by one month
    nextTick: (tick) ->
      tick.clone().addMonths 1
