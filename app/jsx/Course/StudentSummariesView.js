import $ from 'jquery'
import { useScope as useI18nScope } from '@canvas/i18n';
import PaginatedView from '@canvas/pagination/backbone/views/PaginatedView'
import StudentSummaryView from '../Course/StudentSummaryView'

const I18n = useI18nScope('student_summary');

export default class StudentSummariesView extends PaginatedView {
  initialize() {
    super.initialize(...arguments)
    this.$rows = this.$('tbody.rows')
    this.collection.on('reset', () => this.render())
    this.collection.on('sync', () => this.render())
    this.collection.on('add', this.addOne)
    this.$('.student .sortable').addClass('headerSortUp')
    // @$('.sortable').attr('tabindex', '0').attr('role', 'button').click(@sort).on 'keydown', (e) =>
    this.$('.sortable')
      .click(e => this.sort(e))
      .on('keydown', e => {
        if (e.keyCode === 13 || e.keyCode === 32) {
          e.preventDefault()
          return this.sort(e)
        }
      })
  }

  render() {
    this.$rows.empty()
    this.collection.each(this.addOne)
    return super.render(...arguments)
  }

  addOne = summary => {
    const view = new StudentSummaryView({model: summary})
    this.$rows.append(view.$el)
  }

  sort = event => {
    let flashMessage, sortClass
    const $target = $(event.currentTarget)
    const $targetHeader = $target.parents('th')
    let sortKey = $target.data('sort_key')
    const sortCol = $targetHeader.text()
    if ($target.hasClass('headerSortUp')) {
      sortKey = `${sortKey}_descending`
      sortClass = 'headerSortDown'
      $targetHeader.attr('aria-sort', 'descending')
      $targetHeader.find('.screenreader-only').text(I18n.t('sorted descending.'))
      flashMessage = I18n.t('%{col} is sorted descending.', {col: sortCol})
    } else {
      sortKey = `${sortKey}_ascending`
      sortClass = 'headerSortUp'
      $targetHeader.find('.screenreader-only').text(I18n.t('sorted ascending.'))
      flashMessage = I18n.t('%{col} is sorted ascending', {col: sortCol})
    }

    $targetHeader
      .siblings('[aria-sort]')
      .attr('aria-sort', 'none')
      .find('.screenreader-only')
      .text(I18n.t('Click to sort.'))
    this.$('.sortable')
      .removeClass('headerSortUp')
      .removeClass('headerSortDown')
    $target.addClass(sortClass)
    $.screenReaderFlashMessage(flashMessage) // because NVDA and JAWS don't re-read the column
    // heading after we click and sort the other direction
    return this.collection.setSortKey(sortKey)
  }
}
