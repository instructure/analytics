define [
  'Backbone'
  'analytics/compiled/Course/StudentSummaryModel'
], (Backbone, StudentSummaryModel) ->

  class StudentSummaryCollection extends Backbone.Collection
    model: StudentSummaryModel
