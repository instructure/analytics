import Backbone from '@canvas/backbone'

export default class StudentInCourseModel extends Backbone.Model {
  // #
  // Set the student to the student with the given id, if known. Returns true
  // on success, false if the student was not found.
  selectStudent = studentId => {
    let student
    const students = this.get('course').get('students')
    if ((student = students.get(studentId))) {
      return this.set({student})
    }
  }

  // #
  // Retrieve the fragment of the current student.
  currentFragment() {
    return this.get('student').get('id')
  }

  // #
  // Override set to catch when we're setting the student and make sure we
  // start its data loading *before* it gets set (and the change:student event
  // fires).
  set(assignments, ...rest) {
    if (assignments.student != null) {
      assignments.student.ensureData()
    }
    return super.set(assignments, ...Array.from(rest))
  }
}
