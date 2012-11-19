define [
  'compiled/views/PaginatedView'
  'analytics/compiled/Course/StudentSummaryView'
], (PaginatedView, StudentSummaryView) ->

  class StudentSummariesView extends PaginatedView
    initialize: ->
      super
      @$rows = @$('tbody.rows')
      @collection.on 'reset', @render
      @collection.on 'add', @addOne

    render: =>
      @$rows.empty()
      @collection.each @addOne
      super

    addOne: (summary) =>
      view = new StudentSummaryView model: summary
      @$rows.append view.$el
