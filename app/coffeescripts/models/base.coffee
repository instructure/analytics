define [ 'jquery', 'jquery.ajaxJSON' ], ($) ->

  ##
  # Base class for all the analytics data models. Performs an AJAX GET of a url
  # with parameters, then populates internal data structures from the response.
  # Allows you to wait on data population with the "ready" method.
  class Base
    ##
    # Takes the url and the parameters to pass to the url.
    constructor: (url, parameters={}) ->
      deferred = $.Deferred()
      @loading = deferred.promise()

      $.ajaxJSON url, 'GET', parameters,
        # success
        (data) =>
          @populate(data)
          deferred.resolve()
        # error
        (data) ->
          deferred.reject()

    ##
    # Process the data returned by the ajax call to populate the data model.
    # Should be overridden in derived classes.
    populate: (data) ->

    ##
    # Pipes the requested operation after the promise that waits on the object
    # being initialized. example:
    #
    #   promisedBar = myThing.ready -> myThing.bar
    #   promisedBar.done (bar) ->
    #     console.log(bar)
    #
    # promisedBar is a Promise, just like the return value of $.ajaxJSON.
    #
    # this method is particularly useful for building promises to pass to a
    # graph object's graphDeferred method.
    ready: (operation) ->
      @loading.pipe operation
