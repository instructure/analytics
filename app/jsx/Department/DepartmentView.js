import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../views/jst/department.handlebars'
import DepartmentFilterBox from '../Department/DepartmentFilterBox'
import DepartmentGraphView from '../Department/DepartmentGraphView'
import StatisticsView from '../Department/StatisticsView'
import { useScope as useI18nScope } from '@canvas/i18n';

const I18n = useI18nScope('department_view');

// #
// Aggregate view for the Department Analytics page.
export default class DepartmentView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)

    // render template into anchor $el
    this.$el.html(template({account: this.model.get('account').toJSON()}))

    // filter combobox
    this.filterBox = new DepartmentFilterBox(this.model)
    this.$('#filter_box').append(this.filterBox.$el)
    $('.Button').attr("role", "button")

    // add graph subview
    new DepartmentGraphView({
      model: this.model,
      el: this.$('.department_graphs')
    })

    // add statistics subview
    new StatisticsView({
      model: this.model,
      el: this.$('.department_statistics')
    })

    // cache page elements for updates
    this.$crumb_span = $('#filter_crumb span')
    this.$crumb_link = $('#filter_crumb a')

    // update title and crumb on filter change
    return this.model.on('change:filter', this.updatePage.bind(this))
  }

  // #
  // Update the page title and filter-related crumb text/link to match the
  // current filter.
  updatePage() {
    const account = this.model.get('account')
    const filter = this.model.get('filter')

    document.title = I18n.t('Analytics: %{account_name} -- %{filter_name}', {
      account_name: account.get('name'),
      filter_name: filter.get('label')
    })
    this.$crumb_span.text(filter.get('label'))
    return this.$crumb_link.attr({href: filter.get('url')})
  }
}
