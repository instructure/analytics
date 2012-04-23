define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the message data for the student and course. Exposes the data as the
  # 'messages' property once loaded.
  class Messaging extends Base
    constructor: (@course, @student) ->
      super '/api/v1/analytics/messaging/courses/' + @course.id + '/users/' + @student.id

    populate: (data) ->
      @messages = data
