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

    ##
    # Include tick chrome on Mondays. Draw a grid line and bottom label on
    # each of those ticks, with the day of month as the bottom label. Draw
    # a top label only for chromed ticks that have a different month than
    # the last.
    tickChrome: (tick, last) ->
      # if there are fewer than 14 days, just label every day
      if @binsBetween(@startDate, @endDate) < 14
        unless last? && tick.getMonth() is last.getMonth()
          topLabel = 
            if last? && tick.getFullYear() is last.getFullYear()
              I18n.l "date.formats.short_month", tick
            else
              I18n.l "date.formats.medium_month", tick

        grid: true
        bottomLabel: tick.getDate()
        topLabel: topLabel

      # otherwise, at least two monday's, just label every monday
      else if tick.getDay() is 1
        unless last? && tick.getMonth() is last.getMonth()
          topLabel = 
            if last? && tick.getFullYear() is last.getFullYear()
              I18n.l "date.formats.short_month", tick
            else
              I18n.l "date.formats.medium_month", tick

        grid: true
        bottomLabel: tick.getDate()
        topLabel: topLabel

      else
        {}

    ##
    # Advance by one day.
    nextTick: (tick) ->
      tick.clone().addDays 1
