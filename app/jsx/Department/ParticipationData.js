import BaseData from '../BaseData'

// #
// Loads the participation data for the current account/filter. Exposes the
// data as the 'bins' property once loaded.
export default class ParticipationData extends BaseData {
  constructor(filter) {
    const account = filter.get('account')
    const fragment = filter.get('fragment')
    super(`/api/v1/accounts/${account.get('id')}/analytics/${fragment}/activity`)
  }

  populate(data) {
    this.bins = data.by_date
    this.categoryBins = data.by_category

    // this date is the utc date for the bin, not local. but we'll
    // treat it as local for the purposes of presentation.
    return Array.from(this.bins).map(bin => (bin.date = Date.parse(bin.date)))
  }
}
