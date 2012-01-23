define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the message data for the user and course. Exposes the data as the
  # 'messages' property once loaded.
  class Messaging extends Base
    constructor: (@course, @user) ->
      super '/api/v1/analytics/messaging/courses/' + @course.id + '/users/' + @user.id

    populate: (data) ->
      @messages = data
