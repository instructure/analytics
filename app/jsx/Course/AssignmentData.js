import BaseAssignmentData from '../BaseAssignmentData'

// Version of AssignmentData for a Course
export default class AssignmentData extends BaseAssignmentData {
  constructor(course) {
    super(`courses/${course.get('id')}/analytics`, {async: '1'})
  }
}
