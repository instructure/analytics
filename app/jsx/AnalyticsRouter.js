define ['Backbone'], (Backbone) ->

  ##
  # Handles combobox-based ajax routing on analytics pages.
  class AnalyticsRouter extends Backbone.Router
    initialize: (@model, @opts={}) ->
      @usePushState = window.history && window.history.pushState

      # determine the root of the path (the portion without the fragment)
      root = window.location.pathname
      fragment = new RegExp @model.currentFragment() + '$'
      if root.match fragment
        root = root.replace fragment, ''
      else if not root.match /\/$/
        root += '/'

      if @usePushState
        # pushState available, drive the data from the url
        @route @opts.path, @opts.name, @push
        Backbone.history.start
          root: root
          pushState: true
      else
        # no pushState, override navigate to just set the window location
        @navigate = (fragment) ->
          window.location = root + fragment

    ##
    # translate a fragment navigated to into a change in the model
    push: (fragment) =>
      fragment = fragment.toString().replace window.location.search, ''
      unless @opts.select fragment
        window.location.reload()

    ##
    # navigate to the fragment. if using pushState, update the model (with same
    # 404 handling)
    select: (fragment) ->
      @navigate fragment + window.location.search
      @push fragment if @usePushState
