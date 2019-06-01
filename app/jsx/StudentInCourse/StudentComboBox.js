import ComboBox from 'compiled/widget/ComboBox'
import StudentInCourseRouter from '../StudentInCourse/StudentInCourseRouter'

// #
// A combobox representing the possible filters for the department view.
export default class StudentComboBox extends ComboBox {
  constructor(model) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.match(/_this\d*/)[0];
      eval(`${thisName} = this;`);
    }

    this.model = model
    this.router = new StudentInCourseRouter(this.model)

    // construct combobox
    super(this.model.get('course').get('students').models, {
      value: student => student.get('id'),
      label: student => student.get('name'),
      selected: this.model.get('student').get('id')
    })

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
