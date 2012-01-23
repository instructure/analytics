define ->
  dateToDays: (date) -> parseInt(date.getTime() / (1000*60*60*24), 10)
  dateToHours: (date) -> parseInt(date.getTime() / (1000*60*60), 10)
  hoursToDate: (hours) -> new Date(hours * 1000*60*60)
  dayToDate: (day) -> new Date(day * 1000*60*60*24)
