import _ from 'underscore'
import BaseData from '../BaseData'

// #
// Loads the statistics data for the current account/filter. Exposes
// the data as named properties once loaded.
export default class StatisticsData extends BaseData {
  constructor(filter) {
    const account = filter.get('account')
    const fragment = filter.get('fragment')
    super(`/api/v1/accounts/${account.get('id')}/analytics/${fragment}/statistics`)
  }

  populate(data) {
    return _.extend(this, data)
  }
}
