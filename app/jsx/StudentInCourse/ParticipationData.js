import BaseData from '../BaseData'

//#
// Loads the participation data for the student and course. Exposes the data
// as the 'pageViews' and 'participations' properties once loaded.
export default class ParticipationData extends BaseData {
  constructor(student) {
    const course = student.get('course')
    super(`/api/v1/courses/${course.get('id')}/analytics/users/${student.get('id')}/activity`)
  }

  populate(data) {
    let bin
    this.bins = []

    // maintain one unique bin per date, order of insertion into @bins
    // unimportant
    const binMap = {}
    const binFor = date => {
      if (binMap[date] == null) {
        binMap[date] = {
          date,
          views: 0,
          participations: 0,
          participation_events: []
        }
        this.bins.push(binMap[date])
      }
      return binMap[date]
    }

    // sort the page view data to the appropriate bins
    for (let date in data.page_views) {
      // this date is the day for the bin
      const views = data.page_views[date]
      const view_date = Date.parse(date)
      view_date.setHours(0, 0, 0, 0)
      bin = binFor(view_date)
      bin.views += views
    }

    // sort the participation date to the appropriate bins
    for (let event of Array.from(data.participations)) {
      event.createdAt = Date.parse(event.created_at)
      // bin to the day corresponding to event.createdAt, so that all
      // participations fall in the same bin as their respective page views.
      event.createdAt.setHours(0, 0, 0, 0)
      bin = binFor(event.createdAt)
      bin.participation_events.push(event)
      bin.participations += 1
    }
  }
}
