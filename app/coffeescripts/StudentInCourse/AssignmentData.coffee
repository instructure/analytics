define [ 'analytics/compiled/BaseAssignmentData' ], (BaseAssignmentData) ->

  ##
  # Version of AssignmentData for a StudentInCourse
  class AssignmentData extends BaseAssignmentData
    constructor: (student) ->
      course = student.get 'course'
      super "courses/#{course.get 'id'}/analytics/users/#{student.get 'id'}"
