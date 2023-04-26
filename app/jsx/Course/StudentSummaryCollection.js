import _ from 'underscore'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import StudentSummaryModel from '../Course/StudentSummaryModel'

export default class StudentSummaryCollection extends PaginatedCollection {
  initialize() {
    super.initialize(...arguments)
    this.course = this.options.course
    this.contextAssetString = this.course.asset_string()
    if (this.options.params == null) this.options.params = {}
  }

  parse(response) {
    super.parse(...arguments)
    const students = this.course.get('students')
    return _.map(response, summary => ({
      student: students.get(summary.id),
      pageViews: {
        count: summary.page_views,
        max: summary.max_page_views
      },
      participations: {
        count: summary.participations,
        max: summary.max_participations
      },
      tardinessBreakdown: {
        total: summary.tardiness_breakdown.total,
        onTime: summary.tardiness_breakdown.on_time,
        late: summary.tardiness_breakdown.late,
        missing: summary.tardiness_breakdown.missing,
        floating: summary.tardiness_breakdown.floating
      }
    }))
  }

  setSortKey(sortKey) {
    this.options.params.sort_column = sortKey
    return this.fetch()
  }
}
StudentSummaryCollection.prototype.model = StudentSummaryModel
