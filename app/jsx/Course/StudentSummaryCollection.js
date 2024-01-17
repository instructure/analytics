/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {map} from 'lodash'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import StudentSummaryModel from './StudentSummaryModel'

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
    return map(response, summary => ({
      student: students.get(summary.id),
      pageViews: {
        count: summary.page_views,
        max: summary.max_page_views,
      },
      participations: {
        count: summary.participations,
        max: summary.max_participations,
      },
      tardinessBreakdown: {
        total: summary.tardiness_breakdown.total,
        onTime: summary.tardiness_breakdown.on_time,
        late: summary.tardiness_breakdown.late,
        missing: summary.tardiness_breakdown.missing,
        floating: summary.tardiness_breakdown.floating,
      },
    }))
  }

  setSortKey(sortKey) {
    this.options.params.sort_column = sortKey
    return this.fetch()
  }
}
StudentSummaryCollection.prototype.model = StudentSummaryModel
