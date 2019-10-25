import BaseAssignmentData from '../BaseAssignmentData'

// Version of AssignmentData for a StudentInCourse
export default class AssignmentData extends BaseAssignmentData {
  constructor(student) {
    const course = student.get('course')
    super(`courses/${course.get('id')}/analytics/users/${student.get('id')}`)
  }
}
