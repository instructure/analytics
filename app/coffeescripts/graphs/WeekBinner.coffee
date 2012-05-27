define [
  'analytics/compiled/graphs/Binner'
  'analytics/compiled/helpers'
  'i18nObj'
], (Binner, helpers, I18n) ->

  class WeekBinner extends Binner
    ##
    # Force date to preceding Monday midnight.
    reduce: (date) ->
      date = date.clone().clearTime()
      if date.getDay() is 0
        date.addDays -6
      else if date.getDay() isnt 1
        date.addDays 1 - date.getDay()
      date

    ##
    # Count weeks. Assumes dates are reduced to mondays already.
    binsBetween: (date1, date2) ->
      helpers.daysBetween(date1, date2) / 7

    ##
    # Include tick chrome on first Monday of each month. Draw a grid line
    # and bottom label on each of those ticks, with the month as the bottom
    # label. Draw a top label only for chromed ticks that have a different
    # year than the last.
    tickChrome: (tick, last) ->
      return {} unless tick.getDate() <= 7

      unless last? && tick.getFullYear() is last.getFullYear()
        topLabel = tick.getFullYear()

      grid: true
      bottomLabel: I18n.l("date.formats.short_month", tick)
      topLabel: topLabel

    ##
    # Advance by one week
    nextTick: (tick) ->
      tick.clone().addWeeks 1
