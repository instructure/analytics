define [
  'underscore'
  'analytics/compiled/BaseData'
], (_, BaseData) ->

  ##
  # Loads the statistics data for the current account/filter. Exposes
  # the data as named properties once loaded.
  class StatisticsData extends BaseData
    constructor: (filter) ->
      account = filter.get 'account'
      fragment = filter.get 'fragment'
      super '/api/v1/analytics/statistics/accounts/' + account.get('id') + '/' + fragment

    populate: (data) ->
      _.extend this, data
