define [
  'Backbone'
  'analytics/compiled/Course/StudentCollection'
  'analytics/compiled/Course/StudentSummaryCollection'
  'analytics/compiled/Course/ParticipationData'
  'analytics/compiled/Course/AssignmentData'
  'analytics/compiled/Course/StudentSummaries'
], (Backbone, StudentCollection, StudentSummaryCollection, ParticipationData, AssignmentData, StudentSummaries) ->

  class CourseModel extends Backbone.Model
    initialize: ->
      # translate array of student objects to collection of StudentModels,
      # tying each back to the course
      students = new StudentCollection @get 'students'
      students.each (student) => student.set course: this
      @set
        students: students
        studentSummaries: new StudentSummaryCollection
        participation: new ParticipationData this
        assignments: new AssignmentData this

      new StudentSummaries this
