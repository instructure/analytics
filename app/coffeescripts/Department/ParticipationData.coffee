define [ 'analytics/compiled/BaseData' ], (BaseData) ->

  ##
  # Loads the participation data for the current account/filter. Exposes the
  # data as the 'bins' property once loaded.
  class ParticipationData extends BaseData
    constructor: (filter) ->
      account = filter.get 'account'
      fragment = filter.get 'fragment'
      super "/api/v1/accounts/#{account.get 'id'}/analytics/#{fragment}/activity"

    populate: (data) ->
      @bins = data.by_date
      @categoryBins = data.by_category

      # this date is the utc date for the bin, not local. but we'll
      # treat it as local for the purposes of presentation.
      (bin.date = Date.parse bin.date) for bin in @bins
