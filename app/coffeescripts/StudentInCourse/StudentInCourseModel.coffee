define ['Backbone'], (Backbone) ->

  class StudentInCourseModel extends Backbone.Model
    ##
    # Set the student to the student with the given id, if known. Returns true
    # on success, false if the student was not found.
    selectStudent: (studentId) =>
      students = @get('course').get('students')
      if student = students.get studentId
        @set student: student

    ##
    # Retrieve the fragment of the current student.
    currentFragment: ->
      @get('student').get 'id'

    ##
    # Override set to catch when we're setting the student and make sure we
    # start its data loading *before* it gets set (and the change:student event
    # fires).
    set: (assignments, rest...) ->
      assignments.student.ensureData() if assignments.student?
      super assignments, rest...
