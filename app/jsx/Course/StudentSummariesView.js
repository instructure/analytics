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
      # @$('.sortable').attr('tabindex', '0').attr('role', 'button').click(@sort).on 'keydown', (e) =>
      @$('.sortable').click(@sort).on 'keydown', (e) =>
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
      sortCol = $targetHeader.text()
      if $target.hasClass('headerSortUp')
        sortKey = "#{sortKey}_descending"
        sortClass = 'headerSortDown'
        $targetHeader.attr('aria-sort', 'descending')
        $targetHeader.find('.screenreader-only').text(I18n.t('sorted descending.'))
        flashMessage = I18n.t('%{col} is sorted descending.', {col: sortCol})
      else
        sortKey = "#{sortKey}_ascending"
        sortClass = 'headerSortUp'
        $targetHeader.find('.screenreader-only').text(I18n.t('sorted ascending.'))
        flashMessage = I18n.t('%{col} is sorted ascending', {col: sortCol})

      $targetHeader.siblings('[aria-sort]')
        .attr('aria-sort', 'none')
        .find('.screenreader-only').text(I18n.t('Click to sort.'))
      @$('.sortable').removeClass('headerSortUp').removeClass('headerSortDown')
      $target.addClass(sortClass)
      $.screenReaderFlashMessage(flashMessage)  # because NVDA and JAWS don't re-read the column
                                                # heading after we click and sort the other direction
      @collection.setSortKey sortKey
