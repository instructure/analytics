define [
  'underscore'
  'analytics/compiled/BaseData'
], (_, BaseData) ->

  ##
  # Loads the student summary data for the course. Augments the course's
  # student objects with the data once loaded.
  class StudentSummaries extends BaseData
    constructor: (course) ->
      @students = course.get 'students'
      super '/api/v1/analytics/student_summaries/courses/' + course.get('id')

    populate: (data) ->
      maxPageViews = _.max(data, (summary) -> summary.page_views).page_views
      maxParticipations = _.max(data, (summary) -> summary.participations).participations
      for studentId, summary of data
        @students.get(studentId)?.set
          summary:
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
