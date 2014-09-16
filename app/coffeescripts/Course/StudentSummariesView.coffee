define [
  'i18n!student_summary'
  'compiled/views/PaginatedView'
  'analytics/compiled/Course/StudentSummaryView'
], (I18n, PaginatedView, StudentSummaryView) ->

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
      $tableCaption = $('#student_table_caption')
      $target = $(event.currentTarget)
      $targetHeader = $target.parents('th')
      sortKey = $target.data('sort_key')
      sortText = $target.text()
      if $target.hasClass('headerSortDown')
        sortKey = "#{sortKey}_descending"
        sortClass = 'headerSortUp'
        $tableCaption.text I18n.t('student_summary_table_descending', "Student Summary Table sorted descending by %{sortText}", {sortText: sortText})
        $targetHeader.attr 'aria-sort', 'descending'
        $targetHeader.siblings().each (k,v) ->
          $(v).attr 'aria-sort', 'none'
      else
        sortKey = "#{sortKey}_ascending"
        sortClass = 'headerSortDown'
        $tableCaption.text I18n.t('student_summary_table_ascending', "Student Summary Table sorted ascending by %{sortText}", {sortText: sortText})
        $target.parents('th').attr 'aria-sort', 'descending'
        $targetHeader.siblings().each (k,v) ->
          $(v).attr 'aria-sort', 'none'
      @$('.sortable').removeClass('headerSortUp').removeClass('headerSortDown')
      $target.addClass(sortClass)
      @collection.setSortKey sortKey
