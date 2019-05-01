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
    # Label the first tick in a month. If the year has changed,
    # include it in the label
    tickChrome: (tick, last) ->
      return {} unless tick.getDate() <= 7

      label: if !last? or tick.getFullYear() isnt last.getFullYear()
        I18n.l("date.formats.medium_month", tick)
      else
        I18n.l("date.formats.short_month", tick)

    ##
    # Advance by one week
    nextTick: (tick) ->
      tick.clone().addWeeks 1
