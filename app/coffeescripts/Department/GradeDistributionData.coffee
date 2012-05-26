define [
  'underscore'
  'analytics/compiled/BaseData'
], (_, BaseData) ->

  ##
  # Loads the grade distribution data for the current account/filter. Exposes
  # the data as the 'values' property once loaded.
  class GradeDistributionData extends BaseData
    constructor: (filter) ->
      account = filter.get 'account'
      fragment = filter.get 'fragment'
      super '/api/v1/analytics/grades/accounts/' + account.get('id') + '/' + fragment

    populate: (data) ->
      cumulative = 0
      for i in [0..100]
        cumulative += data[i]
      cumulative = 1 if cumulative is 0
      @values = _.map [0..100], (i) -> data[i] / cumulative
