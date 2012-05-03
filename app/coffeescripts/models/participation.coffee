define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the participation data for the student and course. Exposes the data
  # as the 'pageViews' and 'participations' properties once loaded.
  class Participation extends Base
    constructor: (@course, @student=null) ->
      url = '/api/v1/analytics/participation/courses/' + @course.id
      url += '/users/' + @student.id if @student?
      super url

    populate: (data) ->
      @bins = []

      # maintain one unique bin per date, order of insertion into @bins
      # unimportant
      binMap = {}
      binFor = (date) =>
        if !binMap[date]?
          binMap[date] =
            date: date
            total: 0
            pageViews: {}
            participations: []
          @bins.push binMap[date]
        binMap[date]

      # sort the page view data to the appropriate bins
      for date, counts of data.page_views
        # this date is the utc date for the bin, not local. but we'll
        # treat it as local for the purposes of presentation.
        date = Date.parse date
        bin = binFor(date)
        for action, count of counts
          bin.total += count
          bin.pageViews[action] ?= 0
          bin.pageViews[action] += count

      # sort the participation date to the appropriate bins
      for event in data.participations
        event.createdAt = Date.parse event.created_at
        # bin to the utc date corresponding to event.createdAt, so that all
        # participations fall in the same bin as their respective page views.
        offset = event.createdAt.getTimezoneOffset()
        date = event.createdAt.clone().addMinutes(offset).clearTime()
        bin = binFor(date)
        bin.participations.push event
