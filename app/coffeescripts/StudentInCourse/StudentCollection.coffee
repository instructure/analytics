define [
  'Backbone'
  'analytics/compiled/StudentInCourse/StudentModel'
], (Backbone, StudentModel) ->

  class StudentCollection extends Backbone.Collection
    model: StudentModel
