define ->
  obj =
    dateToDays: (date) -> parseInt(date.getTime() / (1000*60*60*24))
    dateToHours: (date) -> parseInt(date.getTime() / (1000*60*60))
