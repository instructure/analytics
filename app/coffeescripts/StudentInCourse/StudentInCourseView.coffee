define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/student_in_course'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/responsiveness'
  'analytics/compiled/graphs/assignment_tardiness'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/colors'
  'compiled/widget/ComboBox'
], ($, _, Backbone, template, PageViews, Responsiveness, AssignmentTardiness, Grades, colors, ComboBox) ->

  class StudentInCourseView extends Backbone.View
    initialize: ->
      # build view
      @$el = $ template
        student: @model.get 'student'
        course: @model.get 'course'

      # cache elements for updates
      @$avatar = @$('.avatar')
      @$course_link = @$('.course_link')
      @$current_score = @$('.current_score')

      if @model.get('students').length > 1
        # build combobox of student names to replace name element
        @comboBox = new ComboBox @model.get('students'),
          value: (student) -> student.id
          label: (student) -> student.name
          selected: @model.get('student').id
        @$('.student_link').replaceWith @comboBox.$el

        # drive data from combobox (reverse connection in render)
        @comboBox.on 'change', (student) =>
          @model.set 'student', student

      else
        # cache name element for updates
        @$student_link = @$('.student_link a')

      # setup the graph objects
      @setupGraphs()

      # update pertinent portions any time the model changes
      @model.on 'change:student', @updateStudent
      @model.on 'change:course', @updateCourse
      @model.on 'change:participation', @updateParticipation
      @model.on 'change:messaging', @updateMessaging
      @model.on 'change:assignments', @updateAssignments

      # initial render
      @render()

    ##
    # Update the student summary info.
    # TODO: I18n
    updateStudent: =>
      student = @model.get 'student'
      @$avatar.attr src: student.avatar_url
      @$current_score.text if student.current_score? then "#{student.current_score}%" else 'N/A'
      if @$student_link?
        @$student_link.text student.name
        @$student_link.attr src: student.html_url
      if @comboBox?
        @comboBox.select student.id

    ##
    # Update the course summary info.
    updateCourse: =>
      course = @model.get 'course'
      @$course_link.attr src: course.html_url
      @$course_link.text course.name

    ##
    # Update the participation graph.
    updateParticipation: =>
      @pageViews.graph @model.get 'participation'

    ##
    # Update the responiveness graph.
    updateMessaging: =>
      @responsiveness.graph @model.get 'messaging'

    ##
    # Update the assignments graphs.
    updateAssignments: =>
      assignments = @model.get 'assignments'
      @assignmentTardiness.graph assignments
      @grades.graph assignments

    ##
    # Update everything.
    render: =>
      @updateStudent()
      @updateCourse()
      @updateParticipation()
      @updateMessaging()
      @updateAssignments()

    ##
    # Instantiate the graphs.
    setupGraphs: ->
      # colors for the graphs
      frame = "#d7d7d7"
      grid = "#f4f4f4"
      blue = "#29abe1"
      darkgray = "#898989"
      gray = "#a1a1a1"
      lightgray = "#cccccc"
      lightgreen = "#95ee86"
      darkgreen = "#2fa23e"
      lightyellow = "#efe33e"
      darkyellow = "#b3a700"
      lightred = "#dea8a9"
      darkred = "#da181d"

      # setup the graphs
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
        leftPadding: 30  # larger padding on left because of assymetrical
        rightPadding: 15 # responsiveness bubbles

      @pageViews = new PageViews @$("#participating-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 9
        barColor: colors.lightgray
        participationColor: colors.blue

      @responsiveness = new Responsiveness @$("#responsiveness-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 14
        gutterHeight: 22
        markerWidth: 31
        caratOffset: 7
        caratSize: 10
        studentColor: colors.blue
        instructorColor: colors.lightgray

      @assignmentTardiness = new AssignmentTardiness @$("#assignment-finishing-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 10
        barColorOnTime: colors.lightgreen
        diamondColorOnTime: colors.darkgreen
        barColorLate: colors.lightyellow
        diamondColorLate: colors.darkyellow
        diamondColorMissing: colors.darkred
        diamondColorUndated: colors.gray

      @grades = new Grades @$("#grades-graph"), $.extend {}, graphOpts,
        height: 200
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
