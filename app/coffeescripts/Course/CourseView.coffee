define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/course'
  'analytics/compiled/Course/StudentSummariesView'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/finishing_assignments_course'
  'analytics/compiled/graphs/colors'
], ($, _, Backbone, template, StudentSummariesView, PageViews, Grades, FinishingAssignmentsCourse, colors) ->

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

      # initial render
      @render()

    render: =>
      @$course_link.text @model.get('name')

      # draw the graphs
      participation = @model.get('participation')
      assignments = @model.get('assignments')
      @pageViews.graph participation
      @finishing.graph assignments
      @grades.graph assignments

      # render the student summaries
      @studentSummaries?.render()

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
        whiskerColor: colors.blue
        boxColor: colors.blue
        medianColor: colors.darkblue
