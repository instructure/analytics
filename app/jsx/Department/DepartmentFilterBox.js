import ComboBox from '@canvas/combo-box'
import DepartmentRouter from '../Department/DepartmentRouter'

export default class DepartmentFilterBox extends ComboBox {
  constructor(model) {
    // construct combobox
    super(model.get('filters').models, {
      value: filter => filter.get('id'),
      label: filter => filter.get('label'),
      selected: model.get('filter').get('id')
    })
    this.model = model

    // add a router tied to the model
    this.router = new DepartmentRouter(this.model)


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
