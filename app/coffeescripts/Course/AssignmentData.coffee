define [ 'analytics/compiled/BaseAssignmentData' ], (BaseAssignmentData) ->

  ##
  # Version of AssignmentData for a Course
  class AssignmentData extends BaseAssignmentData
    constructor: (course) ->
      super "courses/#{course.get 'id'}/analytics", { async: '1' }
