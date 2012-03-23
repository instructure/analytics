define [
  'underscore'
  'Backbone'
  'analytics/compiled/models/participation'
  'analytics/compiled/models/messaging'
  'analytics/compiled/models/assignments'
], (_, Backbone, Participation, Messaging, Assignments) ->

  cache = {}

  class StudentInCourseModel extends Backbone.Model
    initialize: ->
      @updateDependents()
      @on 'change', @updateDependents

    loadById: (courseId, studentId) ->
      return if courseId is @get('course').id && studentId is @get('student').id
      course = _.find @get('courses'), (course) -> course.id is courseId
      student = _.find @get('students'), (student) -> student.id is studentId
      @set course: course, student: student

    updateDependents: =>
      course = @get 'course'
      student = @get 'student'
      if course? && student?
        @set @cachedDependents(course, student)
      else
        @unset 'participation'
        @unset 'messaging'
        @unset 'assignments'

    cachedDependents: (course, student) ->
      cache[course.id] ?= {}
      cache[course.id][student.id] ?=
        participation: new Participation course, student
        messaging:     new Messaging     course, student
        assignments:   new Assignments   course, student
      cache[course.id][student.id]
