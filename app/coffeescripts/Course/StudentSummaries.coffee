define [
  'underscore'
  'analytics/compiled/BaseData'
], (_, BaseData) ->

  ##
  # Loads the student summary data for the course. Augments the course's
  # student objects with the data once loaded.
  class StudentSummaries extends BaseData
    constructor: (@course) ->
      @course.get('studentSummaries').loading = true
      @course.get('studentSummaries').truncated = false
      super "/api/v1/courses/#{@course.get 'id'}/analytics/student_summaries"

    populate: (data) ->
      students = @course.get 'students'
      summaries = @course.get 'studentSummaries'

      maxPageViews = _.max _.map data, (summary) -> summary.page_views
      maxParticipations = _.max _.map data, (summary) -> summary.participations

      summaries.loading = false
      summaries.truncated = data.length < students.size()
      summaries.reset _.map data, (summary) ->
        student: students.get summary.id
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
