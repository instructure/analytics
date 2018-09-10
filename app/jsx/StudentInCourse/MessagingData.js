import BaseData from '../BaseData'

// #
// Loads the message data for the student and course. Exposes the data as the
// 'messages' property once loaded.
export default class MessagingData extends BaseData {
  constructor(student) {
    const course = student.get('course')
    super(`/api/v1/courses/${course.get('id')}/analytics/users/${student.get('id')}/communication`)
  }

  populate(data) {
    this.bins = []

    // maintain one unique bin per date, order of insertion into @bins
    // unimportant
    const binMap = {
      student: {},
      instructor: {}
    }
    const binFor = (date, track) => {
      if (binMap[track][date] == null) {
        binMap[track][date] = {
          date,
          track,
          messages: 0
        }
        this.bins.push(binMap[track][date])
      }
      return binMap[track][date]
    }

    for (let date in data) {
      // this date is the utc date for the bin, not local. but we'll
      // treat it as local for the purposes of presentation.
      const counts = data[date]
      date = Date.parse(date)
      if (counts.studentMessages != null) {
        binFor(date, 'student').messages += counts.studentMessages
      }
      if (counts.instructorMessages != null) {
        binFor(date, 'instructor').messages += counts.instructorMessages
      }
    }
  }
}
