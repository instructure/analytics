define [
  'jquery'
  'compiled/models/ContentMigrationProgress'
  'jquery.ajaxJSON'
], ($, ProgressModel) ->

  ##
  # Base class for all the analytics data models. Performs an AJAX GET of a url
  # with parameters, then populates internal data structures from the response.
  # Allows you to wait on data population with the "ready" method.
  class BaseData
    ##
    # Takes the url and the parameters to pass to the url.
    constructor: (url, parameters={}) ->
      deferred = $.Deferred()
      @loading = deferred.promise()
      @getData(url, parameters, deferred)

    getData: (url, parameters, deferred) ->
      $.ajaxJSON url, 'GET', parameters,
        # success
        (data) =>
          if data.progress_url
            @progress = new ProgressModel
              url: data.progress_url
            @progress.poll().then =>
              @getData(url, parameters, deferred)
          else
            @populate(data)
            @loading = null
            deferred.resolve()

        # error
        (data) ->
          deferred.reject()


    ##
    # Process the data returned by the ajax call to populate the data model.
    # Should be overridden in derived classes.
    populate: (data) ->
