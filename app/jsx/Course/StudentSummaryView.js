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

import $ from 'jquery'
import {omit} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../views/jst/course_student_summary.handlebars'

export default class StudentSummaryView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    return this.render()
  }

  render() {
    const json = omit(this.model.get('student').toJSON(), 'html_url')
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
