define [
  'react'
  'jquery'
  'underscore'
  'Backbone'
  '../../views/jst/student_in_course.handlebars'
  'jst/_avatar'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/responsiveness'
  'analytics/compiled/graphs/assignment_tardiness'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/colors'
  'analytics/compiled/StudentInCourse/StudentComboBox'
  'i18n!student_in_course_view'
  'analytics/compiled/graphs/util'
  'analytics/compiled/jsx/components/ActivitiesTable'
  'analytics/compiled/jsx/components/StudentSubmissionsTable'
  'analytics/compiled/jsx/components/GradesTable'
  'analytics/compiled/jsx/components/ResponsivenessTable'
  'analytics/compiled/helpers'
], (React, $, _, Backbone, template, avatarPartial, PageViews, Responsiveness, AssignmentTardiness, Grades, colors, StudentComboBox, I18n, util, ActivitiesTable, StudentSubmissionsTable, GradesTable, ResponsivenessTable, helpers) ->

  class StudentInCourseView extends Backbone.View
    initialize: ->
      super

      course = @model.get('course')
      student = @model.get('student')
      students = course.get('students')

      # build view
      @$el = $ template
        student: _.omit(student.toJSON(), 'html_url')
        course: course.toJSON()

      # cache elements for updates
      @$crumb_span = $('#student_analytics_crumb span')
      @$crumb_link = $('#student_analytics_crumb a')
      @$student_link = @$('.student_link')
      @$current_score = @$('.current_score')

      if students.length > 1
        # build combobox of student names to replace name element
        @comboBox = new StudentComboBox @model
        @$('.students_box').html @comboBox.$el

      # setup the graph objects
      @setupGraphs()

      # render now and any time the model changes or the window resizes
      @render()
      @afterRender()
      @model.on 'change:student', =>
        @render()
        @afterRender()
      $(window).on 'resize', _.debounce =>
        newWidth = util.computeGraphWidth()
        @pageViews.resize(width: newWidth)
        @responsiveness.resize(width: newWidth)
        @assignmentTardiness.resize(width: newWidth)
        @grades.resize(width: newWidth)
        @render()
        @afterRender()
      ,
        200

    formatTableData: (table) ->
      data = table.data

      if data.bins? or data.assignments?
        data = if data.bins then data.bins else data.assignments

      if typeof table.format is "function"
        data = data.map (item) ->
          table.format(item)

      if (table.div == "#responsiveness-table")
        data = @formatResponsivenessData(data)

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

    ##
    # This will get things into the proper format we need
    # for the responsiveness table. It produces an array
    # of objects in this format:
    # {
    #   date: Date
    #   instructorMessages: Number
    #   studentMessages: Number
    # }
    formatResponsivenessData: (data) ->
      groups = _.groupBy(data, 'date')
      Object.keys(groups).map((key) ->
        date: new Date(key),
        instructorMessages: groups[key].filter((obj) -> obj.track == 'instructor').length,
        studentMessages: groups[key].filter((obj) -> obj.track == 'student').length
      )

    afterRender: ->
      # render the table versions of the graphs for a11y/KO
      @renderTables([
        {
          div: "#participating-table"
          component: ActivitiesTable
          data: @model.get('student').get('participation')
          sort: (a, b) ->
            b.date - a.date
        },
        {
          div: "#responsiveness-table",
          component: ResponsivenessTable,
          data: @model.get('student').get('messaging')
          sort: (a, b) ->
            b.date - a.date
        },
        {
          div: "#assignment-finishing-table"
          component: StudentSubmissionsTable
          data: @model.get('student').get('assignments')
          format: (assignment) ->

            formattedStatus = switch assignment.original.status
              when "late" then I18n.t("Late")
              when "missing" then I18n.t("Missing")
              when "on_time" then I18n.t("On Time")
              when "floating" then I18n.t("Future")

            title: assignment.title
            dueAt: assignment.dueAt,
            submittedAt: assignment.submittedAt,
            status: formattedStatus,
            score: assignment.studentScore
        },
        {
          div: "#grades-table"
          component: GradesTable
          data: @model.get('student').get('assignments')
          format: (assignment) ->
            scoreType = if assignment.scoreDistribution?
                          if assignment.studentScore >= assignment.scoreDistribution.median
                            I18n.t("Good")
                          else if assignment.studentScore >= assignment.scoreDistribution.firstQuartile
                            I18n.t("Fair")
                          else
                            I18n.t("Poor")
                        else
                          I18n.t("Good")

            title:            assignment.title
            min_score:        assignment.scoreDistribution?.minScore
            median:           assignment.scoreDistribution?.median
            max_score:        assignment.scoreDistribution?.maxScore
            points_possible:  assignment.pointsPossible
            student_score:    assignment.studentScore
            score_type:       scoreType
            percentile:
              min: assignment.scoreDistribution?.firstQuartile
              max: assignment.scoreDistribution?.thirdQuartile
        }
      ])

    ##
    # TODO: I18n
    render: =>
      course = @model.get 'course'
      student = @model.get 'student'

      document.title = I18n.t("Analytics: %{course_code} -- %{student_name}",
        {course_code: course.get('course_code'), student_name: student.get('short_name')})
      @$crumb_span.text student.get 'short_name'
      @$crumb_link.attr href: student.get 'analytics_url'

      @$('.avatar').replaceWith(avatarPartial(_.omit(student.toJSON(), 'html_url')))
      @$student_link.text student.get 'name'
      @$student_link.attr href: student.get 'html_url'

      # hide message link unless url is present
      if message_url = student.get('message_student_url')
        @$('.message_student_link').show()
        @$('.message_student_link').attr href: message_url
      else
        @$('.message_student_link').hide()

      current_score = student.get 'current_score'
      if current_score != null
        @$current_score.text "#{current_score}%"
      else
        @$current_score.text 'N/A'

      participation = student.get('participation')
      messaging = student.get('messaging')
      assignments = student.get('assignments')

      @pageViews.graph participation
      @responsiveness.graph messaging
      @assignmentTardiness.graph assignments
      @grades.graph assignments

    ##
    # Instantiate the graphs.
    setupGraphs: ->
      # setup the graphs
      graphOpts =
        width: util.computeGraphWidth()
        frameColor: colors.frame
        gridColor: colors.grid
        horizontalMargin: 40

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        leftPadding: 30  # larger padding on left because of assymetrical
        rightPadding: 15 # responsiveness bubbles

      @pageViews = new PageViews @$("#participating-graph"), $.extend {}, dateGraphOpts,
        height: 150
        barColor: colors.lightblue
        participationColor: colors.darkblue

      @responsiveness = new Responsiveness @$("#responsiveness-graph"), $.extend {}, dateGraphOpts,
        height: 110
        verticalPadding: 4
        gutterHeight: 32
        markerWidth: 31
        caratOffset: 7
        caratSize: 10
        studentColor: colors.orange
        instructorColor: colors.blue

      @assignmentTardiness = new AssignmentTardiness @$("#assignment-finishing-graph"), $.extend {}, dateGraphOpts,
        height: 250
        colorOnTime: colors.sharpgreen
        colorLate: colors.sharpyellow
        colorMissing: colors.sharpred
        colorUndated: colors.frame

      @grades = new Grades @$("#grades-graph"), $.extend {}, graphOpts,
        height: 250
        whiskerColor: colors.frame
        boxColor: colors.grid
        medianColor: colors.frame
        colorGood: colors.sharpgreen
        colorFair: colors.sharpyellow
        colorPoor: colors.sharpred
