define [
  'Backbone'
  'analytics/compiled/Department/FilterModel'
], (Backbone, FilterModel) ->

  class FilterCollection extends Backbone.Collection
    model: FilterModel
