define [
  'Backbone'
  'analytics/compiled/StudentInCourse/ParticipationData'
  'analytics/compiled/StudentInCourse/MessagingData'
  'analytics/compiled/StudentInCourse/AssignmentData'
], (Backbone, ParticipationData, MessagingData, AssignmentData) ->

  class StudentModel extends Backbone.Model
    ##
    # Make sure all the data is either loading or loaded.
    ensureData: ->
      {participation, messaging, assignments} = @attributes
      participation ?= new ParticipationData this
      messaging ?= new MessagingData this
      assignments ?= new AssignmentData this
      @set {participation, messaging, assignments}
