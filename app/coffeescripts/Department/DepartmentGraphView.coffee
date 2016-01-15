define [
  'Backbone'
  'underscore'
  'analytics/jst/department_graphs'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/CategorizedPageViews'
  'analytics/compiled/graphs/GradeDistribution'
  'analytics/compiled/graphs/colors'
], (Backbone, _, template, PageViews, CategorizedPageViews, GradeDistribution, colors) ->

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
        width: Math.max(window.innerWidth - 100, 400)
        height: 150
        frameColor: colors.frame
        gridColor: colors.grid
        topMargin: 15
        verticalMargin: 15
        horizontalMargin: 50
        padding: 10

      @pageViews = new PageViews @$("#participating-date-graph"), $.extend {}, @graphOpts,
        startDate: filter.get 'startDate'
        endDate: filter.get 'endDate'
        verticalPadding: 9
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
        bottomMargin: 35
      @gradeDistribution.graph filter.get 'gradeDistribution'
