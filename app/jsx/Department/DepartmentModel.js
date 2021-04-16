import Backbone from '@canvas/backbone'
import helpers from '../helpers'
import AccountModel from '../Department/AccountModel'
import FilterCollection from '../Department/FilterCollection'

// #
// Represents the collection of data the drives the Department Analytics page.
export default class DepartmentModel extends Backbone.Model {
  // #
  // Translate the raw objects from the environment into models, and parse the
  // start/end dates.
  initialize() {
    let {account, filters, filter} = this.toJSON()
    account = new AccountModel(account)
    filters = new FilterCollection(filters)
    filters.each(filter => filter.set({account}))
    filter = filters.get(filter)
    return this.set({account, filters, filter})
  }

  // #
  // Set the filter to the filter with the given id, if known. Returns true on
  // success, false if the filter was not found.
  selectFilter(filterId) {
    let filter
    if ((filter = this.get('filters').get(filterId))) {
      this.set({filter})
      return true
    } else {
      return false
    }
  }

  // #
  // Retrieve the fragment of the current filter.
  currentFragment() {
    return this.get('filter').get('fragment')
  }

  // #
  // Override set to catch when we're setting the filter and make sure we
  // start its data loading *before* it gets set (and the change:filter event
  // fires).
  set(assignments, ...rest) {
    if ((assignments.filter != null ? assignments.filter.ensureData : undefined) != null) {
      assignments.filter.ensureData()
    }
    return super.set(assignments, ...Array.from(rest))
  }
}
