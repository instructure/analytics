define ['analytics/compiled/AnalyticsRouter'], (AnalyticsRouter) ->

  ##
  # Routes based on the list of known filters in the provided model.
  class DepartmentRouter extends AnalyticsRouter
    initialize: (@model) ->
      super @model,
        path:
          if @model.currentFragment() in ['current', 'completed']
            # allow routing to 'current' or 'completed' iff we started at one of
            # those fragments.
            ':filter'
          else
            # otherwise, only allow routing to other terms
            'terms/:term'
        name: 'filter'
        trigger: 'change:filter'
        select: (fragment) =>
          filter = fragment.toString().replace /^terms\//, ''
          @model.selectFilter filter
