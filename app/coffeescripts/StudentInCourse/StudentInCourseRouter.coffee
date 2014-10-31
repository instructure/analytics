define ['analytics/compiled/AnalyticsRouter'], (AnalyticsRouter) ->

  ##
  # Routes based on the list of students in the course.
  class StudentInCourseRouter extends AnalyticsRouter
    initialize: (@model) ->
      super @model,
        path: ':student'
        name: 'studentInCourse'
        trigger: 'change:student'
        select: @model.selectStudent
