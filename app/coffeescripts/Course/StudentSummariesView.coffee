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
      @$('.student .sortable').addClass 'headerSortUp'
      @$('.sortable').attr('tabindex', '0').attr('role', 'button').click(@sort).on 'keydown', (e) =>
        if e.keyCode == 13 || e.keyCode == 32
          e.preventDefault()
          @sort(e)

    render: =>
      @$rows.empty()
      @collection.each @addOne
      super

    addOne: (summary) =>
      view = new StudentSummaryView model: summary
      @$rows.append view.$el

    sort: (event) =>
      $target = $(event.currentTarget)
      $targetHeader = $target.parents('th')
      sortKey = $target.data('sort_key')
      if $target.hasClass('headerSortUp')
        sortKey = "#{sortKey}_descending"
        sortClass = 'headerSortDown'
        $targetHeader.attr 'aria-sort', 'descending'
        $targetHeader.siblings().removeAttr('aria-sort')
        sortText = I18n.t "Sorted Descending"
      else
        sortKey = "#{sortKey}_ascending"
        sortClass = 'headerSortUp'
        $target.parents('th').attr 'aria-sort', 'ascending'
        $targetHeader.siblings().removeAttr('aria-sort')
        sortText = I18n.t "Sorted Ascending"
      @$('.sortable').removeClass('headerSortUp').removeClass('headerSortDown')
      $target.addClass(sortClass)
      @collection.setSortKey sortKey
      $('#students thead .sort_text').remove()
      $target.append $("<span class='screenreader-only sort_text'></span>").text(' ' + sortText)

