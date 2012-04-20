define [
  'Backbone'
  'analytics/compiled/models/participation'
  'analytics/compiled/models/messaging'
  'analytics/compiled/models/assignments'
], (Backbone, Participation, Messaging, Assignments) ->

  class StudentInCourseModel extends Backbone.Model
    initialize: ->
      @updateDependents()
      @on 'change', @updateDependents

    updateDependents: =>
      course = @get 'course'
      student = @get 'student'
      if course? && student?
        @set
          participation: new Participation course, student
          messaging: new Messaging course, student
          assignments: new Assignments course, student
      else
        @unset 'participation'
        @unset 'messaging'
        @unset 'assignments'
