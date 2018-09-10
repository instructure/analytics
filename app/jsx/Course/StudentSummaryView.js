import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import template from '../../views/jst/course_student_summary.handlebars'

export default class StudentSummaryView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    return this.render()
  }

  render() {
    const json = _.omit(this.model.get('student').toJSON(), 'html_url')
    json.pageViews = this.model.get('pageViews').count
    json.participations = this.model.get('participations').count
    const subs = this.model.get('tardinessBreakdown')
    // Missing submissions aren't actually submissions yet.  Neither are
    // 'floating' (which apparently means 'future' or 'not submitted yet, but
    // also not missing yet')
    json.submissions = subs.total - subs.missing - subs.floating
    json.onTime = subs.onTime
    json.late = subs.late
    json.missing = subs.missing

    // replace $el with new rendering of template
    const oldEl = this.$el
    this.$el = $(template(json))
    oldEl.replaceWith(this.$el)

    return this
  }
}

StudentSummaryView.prototype.tagName = 'tr'
