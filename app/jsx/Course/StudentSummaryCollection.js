define [
  'underscore'
  'compiled/collections/PaginatedCollection'
  'analytics/compiled/Course/StudentSummaryModel'
], (_, PaginatedCollection, StudentSummaryModel) ->

  class StudentSummaryCollection extends PaginatedCollection
    model: StudentSummaryModel

    initialize: ->
      super
      @course = @options.course
      @contextAssetString = @course.asset_string()
      @options.params ?= {}

    parse: (response) ->
      super
      students = @course.get 'students'
      _.map response, (summary) ->
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
          floating: summary.tardiness_breakdown.floating

    setSortKey: (sortKey) =>
      @options.params.sort_column = sortKey
      @fetch()
