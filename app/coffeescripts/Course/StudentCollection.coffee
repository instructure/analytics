define [
  'Backbone'
  'analytics/compiled/Course/StudentModel'
], (Backbone, StudentModel) ->

  class StudentCollection extends Backbone.Collection
    model: StudentModel
