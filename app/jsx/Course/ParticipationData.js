import BaseData from '../BaseData'

// #
// Loads the participation data for the course. Exposes the data as the 'bins'
// property once loaded.
export default class ParticipationData extends BaseData {
  constructor(course) {
    super(`/api/v1/courses/${course.get('id')}/analytics/activity`)
    this.course = course
  }

  populate(data) {
    this.bins = data

    // this date is the utc date for the bin, not local. but we'll
    // treat it as local for the purposes of presentation.
    return Array.from(this.bins).map(bin => (bin.date = Date.parse(bin.date)))
  }
}
