import AnalyticsRouter from '../AnalyticsRouter'

// #
// Routes based on the list of known filters in the provided model.
export default class DepartmentRouter extends AnalyticsRouter {
  initialize(model) {
    let needle
    this.model = model
    return super.initialize(this.model, {
      path: ((needle = this.model.currentFragment()), ['current', 'completed'].includes(needle))
        ? // allow routing to 'current' or 'completed' iff we started at one of
          // those fragments.
          ':filter'
        : // otherwise, only allow routing to other terms
          'terms/:term',
      name: 'filter',
      trigger: 'change:filter',
      select: fragment => {
        const filter = fragment.toString().replace(/^terms\//, '')
        return this.model.selectFilter(filter)
      }
    })
  }
}
