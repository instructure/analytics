define [
  'Backbone'
  'underscore'
  'react'
  '../../views/jst/department_graphs.handlebars'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/CategorizedPageViews'
  'analytics/compiled/graphs/GradeDistribution'
  'analytics/compiled/graphs/colors'
  'analytics/compiled/graphs/util'
  'analytics/compiled/jsx/components/ActivitiesTable'
  'analytics/compiled/jsx/components/ActivitiesByCategory'
  'analytics/compiled/jsx/components/GradeDistributionTable'
  'analytics/compiled/helpers'
], (Backbone, _, React, template, PageViews, CategorizedPageViews, GradeDistribution, colors, util, ActivitiesTable, ActivitiesByCategory, GradeDistributionTable, helpers) ->

  ##
  # Aggregate view for the Department Analytics page.
  class DepartmentGraphView extends Backbone.View
    initialize: ->
      super
      # render now and any time the model changes or the window resizes
      @render()
      @afterRender()
      @model.on 'change:filter', =>
        @render()
        @afterRender()
      $(window).on 'resize', _.debounce =>
        @render()
        @afterRender()
      ,
        200

    formatTableData: (table) ->
      data = table.data

      if data.bins? or data.assignments?
        data = if data.bins then data.bins else data.assignments

      if data.values? and typeof data.values isnt "function"
        data = data.values

      if (table.div == "#participating-category-table")
        data = table.data.categoryBins

      if typeof table.format is "function"
        data = data.map (item, index) ->
          table.format(item, index)

      if typeof table.sort is "function"
        data = data.sort(table.sort)

      data

    renderTable: (table) ->
      React.render(React.createFactory(table.component)({ data: @formatTableData(table), student: true }), $(table.div)[0], helpers.makePaginationAccessible.bind(null, table.div))

    renderTables: (tables = []) ->
      _.each tables, (table) =>
        if table.data.loading?
          table.data.loading.done =>
            @renderTable(table)
        else
          @renderTable(table)

    afterRender: ->
      # render the table versions of the graphs for a11y/KO
      @renderTables([
        {
          div: "#participating-date-table"
          component: ActivitiesTable
          data: @model.get('filter').get('participation')
          sort: (a, b) ->
            b.date - a.date
        },
        {
          div: "#participating-category-table"
          component: ActivitiesByCategory
          data: @model.get('filter').get('participation')
        },
        {
          div: "#grade-distribution-table",
          component: GradeDistributionTable,
          data: @model.get('filter').get('gradeDistribution')
          format: (percent, key) ->
            score: key
            percent: percent
        }
      ])
      $toggle = $("#graph_table_toggle")
      if $toggle.is(':checked')
        $toggle.trigger('change')


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
        barColor: colors.lightblue
        participationColor: colors.darkblue
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
