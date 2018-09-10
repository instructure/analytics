export default class Binner {
  constructor(startDate, endDate) {
    this.startDate = startDate
    this.endDate = endDate
  }

  // #
  // Determine the bin (integer) for the date.
  bin(date) {
    const startDate = this.reduce(this.startDate)
    date = this.reduce(date)
    return this.binsBetween(startDate, date)
  }

  // #
  // Determine the number of bins between startDate and endDate (inclusive).
  count() {
    return this.bin(this.endDate) + 1
  }

  // #
  // Yields to the callback once per tick between startDate and endDate, with
  // chrome information (what labels to draw, whether to draw a grid line) for
  // each tick.
  eachTick(callback) {
    let previousTick, chrome

    // skip if we weren't given start/end dates
    if (this.startDate == null || this.endDate == null) return

    // first tick >= @startDate through last tick <= @endDate
    let tick = this.reduce(this.startDate)
    if (tick < this.startDate) tick = this.nextTick(tick)

    while (tick <= this.endDate) {
      chrome = this.tickChrome(tick, previousTick)
      callback(tick, chrome)
      if (chrome && chrome.label) previousTick = tick.clone()
      tick = this.nextTick(tick)
    }

  }

  // #
  // To be implemented by subclasses. Given a date, translate to the date at
  // the left-end of the corresponding bin.
  reduce(date) {}

  // #
  // To be implemented by subclasses. Given two dates, the number of bins
  // between them. e.g. if the bins are days, the number of days between the
  // dates.
  binsBetween(date1, date2) {}

  // #
  // To be implemented by subclasses. Given a tick and the date of the last
  // tick with chrome, determine the chrome for the tick. Chrome includes:
  //
  // - label: the text, if any, to display along the X axis
  tickChrome(tick, last) {}

  // #
  // To be implemented by subclasses. Given a tick, what's the next tick.
  nextTick(tick) {}
}
