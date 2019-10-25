import AnalyticsRouter from '../AnalyticsRouter'

// #
// Routes based on the list of students in the course.
export default class StudentInCourseRouter extends AnalyticsRouter {
  initialize(model) {
    this.model = model
    return super.initialize(this.model, {
      path: ':student',
      name: 'studentInCourse',
      trigger: 'change:student',
      select: this.model.selectStudent
    })
  }
}
