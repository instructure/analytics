define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the message data for the student and course. Exposes the data as the
  # 'messages' property once loaded.
  class Messaging extends Base
    constructor: (@course, @student) ->
      super '/api/v1/analytics/messaging/courses/' + @course.id + '/users/' + @student.id

    populate: (data) ->
      @bins = []

      # maintain one unique bin per date, order of insertion into @bins
      # unimportant
      binMap =
        student: {}
        instructor: {}
      binFor = (date, track) =>
        if !binMap[track][date]?
          binMap[track][date] =
            date: date
            track: track
            messages: 0
          @bins.push binMap[track][date]
        binMap[track][date]

      for date, counts of data
        # this date is the utc date for the bin, not local. but we'll
        # treat it as local for the purposes of presentation.
        date = Date.parse date
        if counts.studentMessages?
          binFor(date, 'student').messages += counts.studentMessages
        if counts.instructorMessages?
          binFor(date, 'instructor').messages += counts.instructorMessages
