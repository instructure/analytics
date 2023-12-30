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

import React from 'react'
import $ from 'jquery'
import {each, debounce} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../views/jst/course.handlebars'
import StudentSummariesView from './StudentSummariesView'
import PageViews from '../graphs/page_views'
import Grades from '../graphs/grades'
import FinishingAssignmentsCourse from '../graphs/finishing_assignments_course'
import colors from '../graphs/colors'
import util from '../graphs/util'
import ActivitiesTable from '../components/ActivitiesTable'
import SubmissionsTable from '../components/SubmissionsTable'
import GradesTable from '../components/GradesTable'
import helpers from '../helpers'

export default class CourseView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)

    // build view
    this.$el = $(
      template({
        course: this.model.toJSON(),
      })
    )

    // cache elements for updates
    this.$course_link = this.$('.course_link')

    // initialize the graphs
    this.setupGraphs()

    // this will be defined iff the user viewing the page has permission to
    // view student details
    const summaries = this.model.get('studentSummaries')
    if (summaries != null) {
      this.studentSummaries = new StudentSummariesView({
        el: this.$('#students')[0],
        collection: summaries,
      })
    } else {
      // remove student summary framework
      this.$('#students').remove()
    }

    // redraw graphs on resize
    $(window).on(
      'resize',
      debounce(() => {
        const newWidth = util.computeGraphWidth()
        this.pageViews.resize({width: newWidth})
        this.finishing.resize({width: newWidth})
        this.grades.resize({width: newWidth})
        this.render()
      }, 200)
    )

    // prep data
    this.participation = this.model.get('participation')
    this.assignments = this.model.get('assignments')

    // initial render
    this.render()
    return this.afterRender()
  }

  render() {
    this.$course_link.text(this.model.get('name'))

    // draw the graphs
    this.pageViews.graph(this.participation)
    this.finishing.graph(this.assignments)
    this.grades.graph(this.assignments)

    // render the student summaries
    if (this.studentSummaries != null) this.studentSummaries.render()
  }

  afterRender() {
    // render the table versions of the graphs for a11y/KO
    return this.renderTables([
      {
        div: '#activities-table',
        component: ActivitiesTable,
        data: this.participation,
        sort: (a, b) => b.date - a.date,
      },
      {
        div: '#submissions-table',
        component: SubmissionsTable,
        data: this.assignments,
        format(assignment) {
          return {
            title: assignment.title,
            late: assignment.tardinessBreakdown.late,
            missing: assignment.tardinessBreakdown.missing,
            onTime: assignment.tardinessBreakdown.onTime,
          }
        },
      },
      {
        div: '#grades-table',
        component: GradesTable,
        data: this.assignments,
        format(assignment) {
          return {
            title: assignment.title,
            min_score:
              assignment.scoreDistribution != null
                ? assignment.scoreDistribution.minScore
                : undefined,
            median:
              assignment.scoreDistribution != null
                ? assignment.scoreDistribution.median
                : undefined,
            max_score:
              assignment.scoreDistribution != null
                ? assignment.scoreDistribution.maxScore
                : undefined,
            points_possible: assignment.pointsPossible,
            percentile: {
              min:
                assignment.scoreDistribution != null
                  ? assignment.scoreDistribution.firstQuartile
                  : undefined,
              max:
                assignment.scoreDistribution != null
                  ? assignment.scoreDistribution.thirdQuartile
                  : undefined,
            },
          }
        },
      },
    ])
  }

  formatTableData(table) {
    let {data} = table

    if (data.bins != null || data.assignments != null) {
      data = data.bins ? data.bins : data.assignments
    }

    if (typeof table.format === 'function') {
      data = data.map(item => table.format(item))
    }

    if (typeof table.sort === 'function') {
      data = data.sort(table.sort)
    }

    return data
  }

  renderTable(table) {
    return React.render(
      React.createFactory(table.component)({data: this.formatTableData(table)}),
      $(table.div)[0],
      helpers.makePaginationAccessible.bind(null, table.div)
    )
  }

  renderTables(tables = []) {
    each(tables, table => {
      if (table.data.loading != null) {
        table.data.loading.done(() => this.renderTable(table))
      } else {
        this.renderTable(table)
      }
    })
  }

  setupGraphs() {
    const graphOpts = {
      width: util.computeGraphWidth(),
      height: 150,
      frameColor: colors.frame,
      gridColor: colors.grid,
      horizontalMargin: 40,
    }

    const dateGraphOpts = $.extend({}, graphOpts, {
      startDate: this.options.startDate,
      endDate: this.options.endDate,
      horizontalPadding: 15,
    })

    this.pageViews = new PageViews(
      $('#participating-graph', this.$el),
      $.extend({}, dateGraphOpts, {
        barColor: colors.lightblue,
        participationColor: colors.darkblue,
      })
    )

    this.finishing = new FinishingAssignmentsCourse(
      $('#finishing-assignments-graph', this.$el),
      $.extend({}, graphOpts, {
        onTimeColor: colors.sharpgreen,
        lateColor: colors.sharpyellow,
        missingColor: colors.sharpred,
      })
    )

    this.grades = new Grades(
      $('#grades-graph', this.$el),
      $.extend({}, graphOpts, {
        height: 200,
        whiskerColor: colors.blue,
        boxColor: colors.blue,
        medianColor: colors.darkblue,
      })
    )
  }
}
