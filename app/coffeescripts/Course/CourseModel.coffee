define [
  'underscore'
  'Backbone'
  'analytics/compiled/models/CourseParticipation'
  'analytics/compiled/models/assignments'
  'analytics/compiled/Course/StudentSummaries'
], (_, Backbone, CourseParticipation, Assignments, StudentSummaries) ->

  cache = {}

  class CourseModel extends Backbone.Model
    initialize: ->
      @updateDependents()
      @on 'change:course', @updateDependents

    loadById: (courseId) ->
      return if courseId is @get('course').id
      course = _.find @get('courses'), (course) -> course.id is courseId
      @set course: course

    updateDependents: ->
      course = @get 'course'
      _.each course.students, (student) =>
        _.extend student, Backbone.Events
      @set @cachedDependents course

    cachedDependents: (course) ->
      cache[course.id] ?=
        participation:    new CourseParticipation course
        assignments:      new Assignments         course
        studentSummaries: new StudentSummaries    course
      cache[course.id]
