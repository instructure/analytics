define [
  'Backbone'
  'analytics/compiled/helpers'
  'analytics/compiled/Department/ParticipationData'
  'analytics/compiled/Department/GradeDistributionData'
  'analytics/compiled/Department/StatisticsData'
], (Backbone, helpers, ParticipationData, GradeDistributionData, StatisticsData) ->

  class FilterModel extends Backbone.Model
    ##
    # Parse start/end date on initial load.
    initialize: ->
      {startDate, endDate} = @toJSON()
      startDate = helpers.midnight Date.parse(startDate), 'floor'
      endDate = helpers.midnight Date.parse(endDate), 'ceil'
      @set {startDate, endDate}

    ##
    # Make sure all the data is either loading or loaded.
    ensureData: ->
      {participation, gradeDistribution, statistics} = @attributes
      participation ?= new ParticipationData this
      gradeDistribution ?= new GradeDistributionData this
      statistics ?= new StatisticsData this
      @set {participation, gradeDistribution, statistics}
