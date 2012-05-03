define ['vendor/date'], ->

  # returns midnight for the given datetime. with mode 'floor' (the default)
  # it's the nearest preceding (or equal) midnight. with mode 'ceil' it's the
  # nearest following (or equal) midnight.
  midnight: (datetime, mode='floor') ->
    result = datetime.clone().clearTime()
    switch mode
      when 'floor' then result
      when 'ceil'
        if result.compareTo(datetime) is 0
          result
        else
          result.addDays(1)

  # returns the integer number of days that endDate is from startDate. assumes
  # the time portions of startDate and endDate are within an hour (not
  # necessarily equal, thanks to DST) of each other (typically both are
  # midnight), though it can tolerate up to 11 hours difference and still be
  # accurate.
  daysBetween: (startDate, endDate) ->
    Math.round((endDate.getTime() - startDate.getTime()) / 86400000)
