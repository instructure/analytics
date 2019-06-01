import ComboBox from 'compiled/widget/ComboBox'
import DepartmentRouter from '../Department/DepartmentRouter'

export default class DepartmentFilterBox extends ComboBox {
  constructor(model) {

    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.match(/_this\d*/)[0];
      eval(`${thisName} = this;`);
    }

    this.model = model

    // add a router tied to the model
    this.router = new DepartmentRouter(this.model)

    // construct combobox
    super(this.model.get('filters').models, {
      value: filter => filter.get('id'),
      label: filter => filter.get('label'),
      selected: this.model.get('filter').get('id')
    })

    // connect combobox to model
    this.on('change', this.push)
    this.model.on('change:filter', this.pull)
  }

  // #
  // Push the current value of the combobox to the URL
  push = filter => this.router.select(filter.get('fragment'))

  // #
  // Pull the current value from the model to the combobox
  pull = () => this.select(this.model.get('filter').get('id'))
}
