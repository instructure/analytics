define [
  'Backbone'
  'underscore'
  'analytics/jst/department_graphs'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/CategorizedPageViews'
  'analytics/compiled/graphs/GradeDistribution'
  'analytics/compiled/graphs/colors'
  'analytics/compiled/graphs/util'
], (Backbone, _, template, PageViews, CategorizedPageViews, GradeDistribution, colors, util) ->

  ##
  # Aggregate view for the Department Analytics page.
  class DepartmentGraphView extends Backbone.View
    initialize: ->
      super
      # render now and any time the model changes or the window resizes
      @render()
      @model.on 'change:filter', @render
      $(window).on 'resize', _.debounce =>
        @render()
      ,
        200

    render: =>
      @$el.html template()

      filter = @model.get 'filter'
      participations = filter.get 'participation'

      @graphOpts =
        width: util.computeGraphWidth()
        height: 150
        frameColor: colors.frame
        gridColor: colors.grid
        horizontalMargin: 50

      @pageViews = new PageViews @$("#participating-date-graph"), $.extend {}, @graphOpts,
        startDate: filter.get 'startDate'
        endDate: filter.get 'endDate'
        horizontalPadding: 15
        barColor: colors.blue
        participationColor: colors.orange
      @pageViews.graph participations

      @categorizedPageViews = new CategorizedPageViews @$("#participating-category-graph"), $.extend {}, @graphOpts,
        bottomMargin: 25
        barColor: colors.blue
        strokeColor: colors.blue
        sortBy: 'views'
      @categorizedPageViews.graph participations

      @gradeDistribution = new GradeDistribution @$("#grade-distribution-graph"), $.extend {}, @graphOpts,
        areaColor: colors.blue
        strokeColor: colors.grid
      @gradeDistribution.graph filter.get 'gradeDistribution'
