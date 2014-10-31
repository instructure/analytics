define [ 'analytics/compiled/BaseData' ], (BaseData) ->

  ##
  # Loads the participation data for the course. Exposes the data as the 'bins'
  # property once loaded.
  class ParticipationData extends BaseData
    constructor: (@course) ->
      super "/api/v1/courses/#{@course.get 'id'}/analytics/activity"

    populate: (data) ->
      @bins = data

      # this date is the utc date for the bin, not local. but we'll
      # treat it as local for the purposes of presentation.
      (bin.date = Date.parse bin.date) for bin in @bins
