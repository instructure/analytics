import _ from 'underscore'
import BaseData from '../BaseData'

// Loads the grade distribution data for the current account/filter. Exposes
// the data as the 'values' property once loaded.
export default class GradeDistributionData extends BaseData {
  constructor(filter) {
    const account = filter.get('account')
    const fragment = filter.get('fragment')
    super(`/api/v1/accounts/${account.get('id')}/analytics/${fragment}/grades`)
  }

  populate(data) {
    let cumulative = 0
    for (let i = 0; i <= 100; i++) {
      cumulative += parseInt(data[i], 10)
    }
    if (cumulative === 0) cumulative = 1
    this.values = Array(101).fill().map((_, i) => data[i] / cumulative)
  }
}
