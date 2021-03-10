import Backbone from '@canvas/backbone'
import StudentCollection from '../Course/StudentCollection'
import StudentSummaryCollection from '../Course/StudentSummaryCollection'
import ParticipationData from '../Course/ParticipationData'
import AssignmentData from '../Course/AssignmentData'

export default class CourseModel extends Backbone.Model {
  initialize() {
    let students
    this.set({
      participation: new ParticipationData(this),
      assignments: new AssignmentData(this)
    })

    // if there's student info (only iff the user viewing the page has
    // permission to view their details), package it up in a collection and
    // start loading the summaries
    if ((students = this.get('students'))) {
      students = new StudentCollection(students)
      students.each(student => student.set({course: this}))
      this.set({
        students,
        studentSummaries: new StudentSummaryCollection([], {course: this})
      })
      return this.get('studentSummaries').fetch()
    }
  }

  asset_string() {
    return `course_${this.get('id')}`
  }
}
