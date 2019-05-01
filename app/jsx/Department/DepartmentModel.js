define [
  'Backbone'
  'analytics/compiled/helpers'
  'analytics/compiled/Department/AccountModel'
  'analytics/compiled/Department/FilterCollection'
], (Backbone, helpers, AccountModel, FilterCollection) ->

  ##
  # Represents the collection of data the drives the Department Analytics page.
  class DepartmentModel extends Backbone.Model

    ##
    # Translate the raw objects from the environment into models, and parse the
    # start/end dates.
    initialize: ->
      {account, filters, filter} = @toJSON()
      account = new AccountModel account
      filters = new FilterCollection filters
      filters.each (filter) => filter.set account: account
      filter = filters.get filter
      @set {account, filters, filter}

    ##
    # Set the filter to the filter with the given id, if known. Returns true on
    # success, false if the filter was not found.
    selectFilter: (filterId) ->
      if filter = @get('filters').get filterId
        @set filter: filter
        return true
      else
        return false

    ##
    # Retrieve the fragment of the current filter.
    currentFragment: ->
      @get('filter').get('fragment')

    ##
    # Override set to catch when we're setting the filter and make sure we
    # start its data loading *before* it gets set (and the change:filter event
    # fires).
    set: (assignments, rest...) ->
      assignments.filter.ensureData() if assignments.filter?.ensureData?
      super assignments, rest...
