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
      @set
        participation: new ParticipationData this
        assignments: new AssignmentData this

      # if there's student info (only iff they user viewing the page has
      # permission to view their details), package it up in a collection and
      # start loading the summaries
      if students = @get 'students'
        students = new StudentCollection students
        students.each (student) => student.set course: this
        @set
          students: students
          studentSummaries: new StudentSummaryCollection
        new StudentSummaries this
