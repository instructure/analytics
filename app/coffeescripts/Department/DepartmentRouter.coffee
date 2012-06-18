define ['Backbone'], (Backbone) ->

  ##
  # Routes based on the list of known filters in the provided model.
  class DepartmentRouter extends Backbone.Router
    initialize: (@model) ->
      route =
        if @model.currentFragment() in ['current', 'completed']
          # allow routing to 'current' or 'completed' iff we started at one of
          # those fragments.
          ':filter'
        else
          # otherwise, only allow routing to other terms
          'terms/:term'

      # connect to the model
      @route route, 'filter', @push
      @model.on 'change:filter', @pull

    ##
    # Push the filter from the route to the model. If it fails (the model
    # doesn't know about that filter), refresh the page at this new url to
    # either correct the data or get the appropriate 404/401/etc. from the
    # server.
    push: (filterId) =>
      filterId = filterId.replace window.location.search, ''
      unless @model.selectFilter filterId
        window.location.reload()

    currentFragment: ->
      @model.currentFragment() + window.location.search

    ##
    # Pull the current filter from the model and navigate to its fragment.
    pull: =>
      @navigate @currentFragment()

    ##
    # Start the History object.
    run: ->
      # start up the history
      location = window.location.pathname
      fragment = new RegExp @currentFragment() + '$'
      if location.match fragment
        location = location.replace fragment, ''
      else if not location.match /\/$/
        location += '/'
      Backbone.history.start
        root: location
        pushState: true
