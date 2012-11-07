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
      super "/api/v1/courses/#{@course.get 'id'}/analytics/student_summaries?per_page=50"

    populate: (data) ->
      students = @course.get 'students'
      summaries = @course.get 'studentSummaries'

      summaries.loading = false
      summaries.truncated = data.length < students.size()
      summaries.reset _.map data, (summary) ->
        student: students.get summary.id
        pageViews:
          count: summary.page_views
          max: summary.max_page_views
        participations:
          count: summary.participations
          max: summary.max_participations
        tardinessBreakdown:
          total: summary.tardiness_breakdown.total
          onTime: summary.tardiness_breakdown.on_time
          late: summary.tardiness_breakdown.late
          missing: summary.tardiness_breakdown.missing
