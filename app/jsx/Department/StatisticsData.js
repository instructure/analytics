define [
  'underscore'
  'analytics/compiled/BaseData'
  'compiled/str/TextHelper'
], (_, BaseData) ->

  ##
  # Loads the statistics data for the current account/filter. Exposes
  # the data as named properties once loaded.
  class StatisticsData extends BaseData
    constructor: (filter) ->
      account = filter.get 'account'
      fragment = filter.get 'fragment'
      super "/api/v1/accounts/#{account.get 'id'}/analytics/#{fragment}/statistics"

    populate: (data) ->
      _.extend this, data
