import $ from 'jquery'
import ProgressModel from '@canvas/content-migrations/backbone/models/ContentMigrationProgress'
import '@canvas/jquery/jquery.ajaxJSON'

// #
// Base class for all the analytics data models. Performs an AJAX GET of a url
// with parameters, then populates internal data structures from the response.
// Allows you to wait on data population with the "ready" method.
export default class BaseData {
  // #
  // Takes the url and the parameters to pass to the url.
  constructor(url, parameters = {}) {
    const deferred = $.Deferred()
    this.loading = deferred.promise()
    this.getData(url, parameters, deferred)
  }

  getData(url, parameters, deferred) {
    return $.ajaxJSON(
      url,
      'GET',
      parameters,
      // success
      data => {
        if (data.progress_url) {
          this.progress = new ProgressModel({
            url: data.progress_url
          })
          return this.progress.poll().then(() => this.getData(url, parameters, deferred))
        } else {
          this.populate(data)
          this.loading = null
          return deferred.resolve()
        }
      },

      // error
      data => deferred.reject()
    )
  }

  // #
  // Process the data returned by the ajax call to populate the data model.
  // Should be overridden in derived classes.
  populate(data) {}
}
