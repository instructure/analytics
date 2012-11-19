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
      @$('.student .sortable').addClass 'headerSortDown'
      @$('.sortable').click @sort

    render: =>
      @$rows.empty()
      @collection.each @addOne
      super

    addOne: (summary) =>
      view = new StudentSummaryView model: summary
      @$rows.append view.$el

    sort: (event) =>
      $target = $(event.currentTarget)
      sortKey = $target.data('sort_key')
      if $target.hasClass('headerSortDown')
        sortKey = "#{sortKey}_descending"
        sortClass = 'headerSortUp'
      else
        sortKey = "#{sortKey}_ascending"
        sortClass = 'headerSortDown'
      @$('.sortable').removeClass('headerSortUp').removeClass('headerSortDown')
      $target.addClass(sortClass)
      @collection.setSortKey sortKey
