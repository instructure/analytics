define [
  'react'
  'jquery'
  'underscore'
  'Backbone'
  '../../views/jst/course.handlebars'
  'analytics/compiled/Course/StudentSummariesView'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/finishing_assignments_course'
  'analytics/compiled/graphs/colors'
  'analytics/compiled/graphs/util'
  'analytics/compiled/jsx/components/ActivitiesTable'
  'analytics/compiled/jsx/components/SubmissionsTable'
  'analytics/compiled/jsx/components/GradesTable'
  'analytics/compiled/helpers'
], (React, $, _, Backbone, template, StudentSummariesView, PageViews, Grades, FinishingAssignmentsCourse, colors, util, ActivitiesTable, SubmissionsTable, GradesTable, helpers) ->

  class CourseView extends Backbone.View
    initialize: ->
      super

      # build view
      @$el = $ template
        course: @model.toJSON()

      # cache elements for updates
      @$course_link = @$('.course_link')

      # initialize the graphs
      @setupGraphs()

      # this will be defined iff the user viewing the page has permission to
      # view student details
      summaries = @model.get('studentSummaries')
      if summaries?
        @studentSummaries = new StudentSummariesView
          el: @$('#students')[0]
          collection: summaries
      else
        # remove student summary framework
        @$('#students').remove()

      # redraw graphs on resize
      $(window).on 'resize', _.debounce =>
        newWidth = util.computeGraphWidth()
        @pageViews.resize(width: newWidth)
        @finishing.resize(width: newWidth)
        @grades.resize(width: newWidth)
        @render()
      ,
        200

      # prep data
      @participation = @model.get('participation')
      @assignments = @model.get('assignments')

      # initial render
      @render()
      @afterRender()

    render: =>
      @$course_link.text @model.get('name')

      # draw the graphs
      @pageViews.graph @participation
      @finishing.graph @assignments
      @grades.graph @assignments

      # render the student summaries
      @studentSummaries?.render()

    afterRender: ->
      # render the table versions of the graphs for a11y/KO
      @renderTables([
        {
          div: "#activities-table"
          component: ActivitiesTable
          data: @participation,
          sort: (a, b) ->
            b.date - a.date
        },
        {
          div: "#submissions-table"
          component: SubmissionsTable
          data: @assignments
          format: (assignment) ->
            title:    assignment.title
            late:     assignment.tardinessBreakdown.late
            missing:  assignment.tardinessBreakdown.missing
            onTime:   assignment.tardinessBreakdown.onTime
        },
        {
          div: "#grades-table"
          component: GradesTable
          data: @assignments
          format: (assignment) ->
            title:            assignment.title
            min_score:        assignment.scoreDistribution?.minScore
            median:           assignment.scoreDistribution?.median
            max_score:        assignment.scoreDistribution?.maxScore
            points_possible:  assignment.pointsPossible
            percentile:
              min: assignment.scoreDistribution?.firstQuartile
              max: assignment.scoreDistribution?.thirdQuartile
        }
      ])

    formatTableData: (table) ->
      data = table.data

      if data.bins? or data.assignments?
        data = if data.bins then data.bins else data.assignments

      if typeof table.format is "function"
        data = data.map (item) ->
          table.format(item)

      if typeof table.sort is "function"
        data = data.sort(table.sort)

      data

    renderTable: (table) ->
      React.render(React.createFactory(table.component)({ data: @formatTableData(table) }), $(table.div)[0], helpers.makePaginationAccessible.bind(null, table.div))

    renderTables: (tables = []) ->
      _.each tables, (table) =>
        if table.data.loading?
          table.data.loading.done =>
            @renderTable(table)
        else
          @renderTable(table)

    setupGraphs: ->
      graphOpts =
        width: util.computeGraphWidth()
        height: 150
        frameColor: colors.frame
        gridColor: colors.grid
        horizontalMargin: 40

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        horizontalPadding: 15

      @pageViews = new PageViews $("#participating-graph", @$el), $.extend {}, dateGraphOpts,
        barColor: colors.lightblue
        participationColor: colors.darkblue

      @finishing = new FinishingAssignmentsCourse $("#finishing-assignments-graph", @$el), $.extend {}, graphOpts,
        onTimeColor: colors.sharpgreen
        lateColor: colors.sharpyellow
        missingColor: colors.sharpred

      @grades = new Grades $("#grades-graph", @$el), $.extend {}, graphOpts,
        height: 200
        whiskerColor: colors.blue
        boxColor: colors.blue
        medianColor: colors.darkblue
