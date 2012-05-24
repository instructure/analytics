define ['Backbone'], (Backbone) ->

  class StudentInCourseModel extends Backbone.Model
    ##
    # Override set to catch when we're setting the student and make sure we
    # start its data loading *before* it gets set (and the change:student event
    # fires).
    set: (assignments, rest...) ->
      assignments.student.ensureData() if assignments.student?
      super assignments, rest...
