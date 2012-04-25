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
        course: @model.get 'course'

      # cache elements for updates
      @$course_link = $('.course_link', @$el)
      @$students = $('#students tbody:last', @$el)

      # initialize the graphs
      @setupGraphs()

      # update relevant portions as data becomes available
      @model.on 'change:course', @updateSummary
      @model.on 'change:participation', @updateParticipation
      @model.on 'change:assignments', @updateAssignments

      # initial render
      @render()

    updateSummary: =>
      course = @model.get 'course'
      @$course_link.text course.name

      # add all the students to the table
      @$students.empty()
      _.each course.students, (student) =>
        view = new StudentSummaryView model: student
        @$students.append view.$el

    updateParticipation: =>
      @pageViews.graph @model.get 'participation'

    updateAssignments: =>
      assignments = @model.get 'assignments'
      @finishing.graph assignments
      @grades.graph assignments

    render: ->
      @updateSummary()
      @updateParticipation()
      @updateAssignments()

    setupGraphs: ->
      graphOpts =
        width: 800
        height: 100
        frameColor: colors.frame
        gridColor: colors.grid
        topMargin: 15
        verticalMargin: 15
        horizontalMargin: 25

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        horizontalPadding: 15

      @pageViews = new PageViews $("#participating-graph", @$el), $.extend {}, dateGraphOpts,
        verticalPadding: 9
        barColor: colors.lightgray
        participationColor: colors.blue

      @finishing = new FinishingAssignmentsCourse $("#finishing-assignments-graph", @$el), $.extend {}, graphOpts,
        padding: 15
        onTimeColor: colors.sharpgreen
        lateColor: colors.sharpyellow
        missingColor: colors.sharpred

      @grades = new Grades $("#grades-graph", @$el), $.extend {}, graphOpts,
        padding: 15
        whiskerColor: colors.darkgray
        boxColor: colors.lightgray
        medianColor: colors.darkgray
        goodRingColor: colors.lightgreen
        goodCenterColor: colors.darkgreen
        fairRingColor: colors.lightyellow
        fairCenterColor: colors.darkyellow
        poorRingColor: colors.lightred
        poorCenterColor: colors.darkred
