define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/course'
  'analytics/compiled/Course/StudentSummaryView'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/finishing_assignments_course'
  'analytics/compiled/graphs/colors'
], ($, _, Backbone, template, StudentSummaryView, PageViews, Grades, FinishingAssignmentsCourse, colors) ->

  class CourseView extends Backbone.View
    initialize: ->
      # build view
      @$el = $ template
        course: @model.toJSON()

      # cache elements for updates
      @$course_link = $('.course_link', @$el)
      @$students = $('#students tbody:last', @$el)

      # initialize the graphs
      @setupGraphs()

      # render
      @render()

    render: =>
      @$course_link.text @model.get('name')

      # draw the graphs
      participation = @model.get('participation')
      assignments = @model.get('assignments')
      @pageViews.graph participation
      @finishing.graph assignments
      @grades.graph assignments

      # add all the students to the table
      @$students.empty()
      @model.get('students').each (student) =>
        view = new StudentSummaryView model: student
        @$students.append view.$el

    setupGraphs: ->
      graphOpts =
        width: 800
        height: 100
        frameColor: colors.frame
        gridColor: colors.grid
        topMargin: 15
        verticalMargin: 15
        horizontalMargin: 40

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        horizontalPadding: 15

      @pageViews = new PageViews $("#participating-graph", @$el), $.extend {}, dateGraphOpts,
        verticalPadding: 9
        barColor: colors.blue
        participationColor: colors.orange

      @finishing = new FinishingAssignmentsCourse $("#finishing-assignments-graph", @$el), $.extend {}, graphOpts,
        padding: 15
        onTimeColor: colors.sharpgreen
        lateColor: colors.sharpyellow
        missingColor: colors.sharpred

      @grades = new Grades $("#grades-graph", @$el), $.extend {}, graphOpts,
        height: 200
        padding: 15
        whiskerColor: colors.lightblue
        boxColor: colors.blue
        medianColor: colors.orange
