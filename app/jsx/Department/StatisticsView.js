import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../views/jst/department_statistics.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'

export default class StatisticsView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    this.model.on('change', this.render)
    return this.render()
  }

  render() {
    const statistics = this.model.get('filter').get('statistics')
    if (statistics != null) {
      const $table = $(template(statistics))
      this.$el.html($table)
      if (statistics.loading != null) {
        $table.disableWhileLoading(statistics.loading)
        statistics.loading.done(this.render)
        statistics.loading.fail(() => {}) // TODO: add error icon
      }
    }
  }
}
