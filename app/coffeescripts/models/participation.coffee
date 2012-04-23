define [ 'analytics/compiled/models/base' ], (Base) ->

  ##
  # Loads the participation data for the student and course. Exposes the data
  # as the 'pageViews' and 'participations' properties once loaded.
  class Participation extends Base
    constructor: (@course, @student) ->
      super '/api/v1/analytics/participation/courses/' + @course.id + '/users/' + @student.id

    populate: (data) ->
      @pageViews = data.page_views
      @participations = data.participations
