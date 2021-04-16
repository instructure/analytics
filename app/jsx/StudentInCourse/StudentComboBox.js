import ComboBox from '@canvas/combo-box'
import StudentInCourseRouter from '../StudentInCourse/StudentInCourseRouter'

// #
// A combobox representing the possible filters for the department view.
export default class StudentComboBox extends ComboBox {
  constructor(model) {
    // construct combobox
    super(model.get('course').get('students').models, {
      value: student => student.get('id'),
      label: student => student.get('name'),
      selected: model.get('student').get('id')
    })
    this.model = model
    this.router = new StudentInCourseRouter(this.model)

    // connect combobox to model
    this.on('change', this.push)
    this.model.on('change:student', this.pull)
  }

  // #
  // Push the current value of the combobox to the URL
  push = student => this.router.select(student.get('id'))

  // #
  // Pull the current value from the model to the combobox
  pull = () => this.select(this.model.get('student').get('id'))
}
