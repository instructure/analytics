import Backbone from '@canvas/backbone'
import StudentCollection from '../StudentInCourse/StudentCollection'

export default class CourseModel extends Backbone.Model {
  initialize() {
    // translate array of student objects to collection of StudentModels,
    // tying each back to the course
    const students = new StudentCollection(this.get('students'))
    students.each(student => student.set({course: this}))
    return this.set({students})
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.url = json.analytics_url != null ? json.analytics_url : json.html_url
    return json
  }
}
