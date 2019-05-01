define [
  'analytics/compiled/graphs/Binner'
  'analytics/compiled/helpers'
  'i18nObj'
], (Binner, helpers, I18n) ->

  class DayBinner extends Binner
    ##
    # Force date to preceding midnight.
    reduce: (date) ->
      date.clone().clearTime()

    ##
    # Count days. Assumes dates are reduced to midnight already.
    binsBetween: (date1, date2) ->
      helpers.daysBetween(date1, date2)

    tickChrome: (tick, last) ->
      # if there are fewer than 14 days, just label every day.
      # include the short month if the month has changed.
      if @binsBetween(@startDate, @endDate) < 14
        label: if !last? || last.getMonth() isnt tick.getMonth()
          I18n.l "date.formats.short", tick
        else
          tick.getDate()

      # otherwise, label the first of each month, including the year
      # if this has changed
      else if tick.getDate() is 1
        label: if !last? || last.getYear() isnt tick.getYear()
          I18n.l "date.formats.medium_month", tick
        else
          I18n.l "date.formats.short_month", tick

      else
        {}

    ##
    # Advance by one day.
    nextTick: (tick) ->
      tick.clone().addDays 1
