define [
  'Backbone'
  'analytics/compiled/StudentInCourse/StudentCollection'
], (Backbone, StudentCollection) ->

  class CourseModel extends Backbone.Model
    initialize: ->
      # translate array of student objects to collection of StudentModels,
      # tying each back to the course
      students = new StudentCollection @get 'students'
      students.each (student) => student.set course: this
      @set students: students

    toJSON: ->
      json = super
      json.url = json.analytics_url ? json.html_url
      json
