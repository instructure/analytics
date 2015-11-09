define [
  'analytics/compiled/BaseData'
  'timezone'
], (BaseData, tz) ->

  ##
  # Loads the participation data for the student and course. Exposes the data
  # as the 'pageViews' and 'participations' properties once loaded.
  class ParticipationData extends BaseData
    constructor: (student) ->
      course = student.get('course')
      super "/api/v1/courses/#{course.get 'id'}/analytics/users/#{student.get 'id'}/activity"

    populate: (data) ->
      @bins = []

      # maintain one unique bin per date, order of insertion into @bins
      # unimportant
      binMap = {}
      binFor = (date) =>
        if !binMap[date]?
          binMap[date] =
            date: date
            views: 0
            participations: 0
          @bins.push binMap[date]
        binMap[date]

      # sort the page view data to the appropriate bins
      for date, views of data.page_views
        # this date is the hour for the bin
        bin = binFor(Date.parse date)
        bin.views += views

      # sort the participation date to the appropriate bins
      for date, events of data.participation_counts
        # this date is the hour for the bin
        bin = binFor(Date.parse date)
        bin.participations += events
