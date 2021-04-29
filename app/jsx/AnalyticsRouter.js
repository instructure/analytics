import Backbone from '@canvas/backbone'

// #
// Handles combobox-based ajax routing on analytics pages.
export default class AnalyticsRouter extends Backbone.Router {
  initialize(model, opts = {}) {
    this.model = model
    this.opts = opts
    this.usePushState = window.history && window.history.pushState

    // determine the root of the path (the portion without the fragment)
    let root = window.location.pathname
    const fragment = new RegExp(`${this.model.currentFragment()}$`)
    if (root.match(fragment)) {
      root = root.replace(fragment, '')
    } else if (!root.match(/\/$/)) {
      root += '/'
    }

    if (this.usePushState) {
      // pushState available, drive the data from the url
      this.route(this.opts.path, this.opts.name, this.push)
      Backbone.history.start({
        root,
        pushState: true
      })
    } else {
      // no pushState, override navigate to just set the window location
      this.navigate = fragment => (window.location = root + fragment)
    }
  }

  // #
  // translate a fragment navigated to into a change in the model
  push = fragment => {
    fragment = fragment.toString().replace(window.location.search, '')
    if (!this.opts.select(fragment)) window.location.reload()
  }

  // #
  // navigate to the fragment. if using pushState, update the model (with same
  // 404 handling)
  select(fragment) {
    this.navigate(fragment + window.location.search)
    if (this.usePushState) {
      return this.push(fragment)
    }
  }
}
