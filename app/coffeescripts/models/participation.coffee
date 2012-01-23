define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the participation data for the user and course. Exposes the data as
  # the 'pageViews' and 'participations' properties once loaded.
  class Participation extends Base
    constructor: (@course, @user) ->
      super '/api/v1/analytics/participation/courses/' + @course.id + '/users/' + @user.id

    populate: (data) ->
      @pageViews = data.page_views
      @participations = data.participations
