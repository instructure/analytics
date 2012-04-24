define [
  'underscore'
  'analytics/compiled/models/base'
], (_, Base) ->

  ##
  # Loads the student summary data for the course. Augments the course's
  # student objects with the data once loaded.
  class StudentSummaries extends Base
    constructor: (@course) ->
      super '/api/v1/analytics/student_summaries/courses/' + @course.id

    populate: (data) ->
      maxPageViews = _.max(data, (summary) -> summary.page_views).page_views
      maxParticipations = _.max(data, (summary) -> summary.participations).participations
      _.each @course.students, (student) ->
        summary = data[student.id]
        if summary?
          student.summary =
            pageViews:
              count: summary.page_views
              max: maxPageViews
            participations:
              count: summary.participations
              max: maxParticipations
            tardinessBreakdown:
              total: summary.tardiness_breakdown.total
              onTime: summary.tardiness_breakdown.on_time
              late: summary.tardiness_breakdown.late
              missing: summary.tardiness_breakdown.missing
        student.trigger 'change'
