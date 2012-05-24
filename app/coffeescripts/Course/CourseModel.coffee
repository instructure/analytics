define [
  'Backbone'
  'analytics/compiled/Course/StudentCollection'
  'analytics/compiled/Course/ParticipationData'
  'analytics/compiled/Course/AssignmentData'
  'analytics/compiled/Course/StudentSummaries'
], (Backbone, StudentCollection, ParticipationData, AssignmentData, StudentSummaries) ->

  class CourseModel extends Backbone.Model
    initialize: ->
      # translate array of student objects to collection of StudentModels,
      # tying each back to the course
      students = new StudentCollection @get 'students'
      students.each (student) => student.set course: this
      @set
        students: students
        participation: new ParticipationData this
        assignments: new AssignmentData this

      # also start loading student summaries
      new StudentSummaries this
