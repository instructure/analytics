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
import Backbone from '@canvas/backbone'
import {debounce, each} from 'lodash'
import React from 'react'
import template from '../../views/jst/department_graphs.handlebars'
import PageViews from '../graphs/page_views'
import CategorizedPageViews from '../graphs/CategorizedPageViews'
import GradeDistribution from '../graphs/GradeDistribution'
import colors from '../graphs/colors'
import util from '../graphs/util'
import ActivitiesTable from '../components/ActivitiesTable'
import ActivitiesByCategory from '../components/ActivitiesByCategory'
import GradeDistributionTable from '../components/GradeDistributionTable'
import helpers from '../helpers'

// #
// Aggregate view for the Department Analytics page.
export default class DepartmentGraphView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    // render now and any time the model changes or the window resizes
    this.render()
    this.afterRender()
    this.model.on('change:filter', () => {
      this.render()
      return this.afterRender()
    })
    $(window).on(
      'resize',
      debounce(() => {
        this.render()
        this.afterRender()
      }, 200)
    )
  }

  formatTableData(table) {
    let {data} = table

    if (data.bins != null || data.assignments != null) {
      data = data.bins ? data.bins : data.assignments
    }

    if (data.values != null && typeof data.values !== 'function') {
      data = data.values
    }

    if (table.div === '#participating-category-table') {
      data = table.data.categoryBins
    }

    if (typeof table.format === 'function') {
      data = data.map((item, index) => table.format(item, index))
    }

    if (typeof table.sort === 'function') {
      data = data.sort(table.sort)
    }

    return data
  }

  renderTable(table) {
    return React.render(
      React.createFactory(table.component)({data: this.formatTableData(table), student: true}),
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

  afterRender() {
    // render the table versions of the graphs for a11y/KO
    this.renderTables([
      {
        div: '#participating-date-table',
        component: ActivitiesTable,
        data: this.model.get('filter').get('participation'),
        sort: (a, b) => b.date - a.date,
      },
      {
        div: '#participating-category-table',
        component: ActivitiesByCategory,
        data: this.model.get('filter').get('participation'),
      },
      {
        div: '#grade-distribution-table',
        component: GradeDistributionTable,
        data: this.model.get('filter').get('gradeDistribution'),
        format(percent, key) {
          return {
            score: key,
            percent,
          }
        },
      },
    ])
    const $toggle = $('#graph_table_toggle')
    if ($toggle.is(':checked')) $toggle.trigger('change')
  }

  render() {
    this.$el.html(template())

    const filter = this.model.get('filter')
    const participations = filter.get('participation')

    this.graphOpts = {
      width: util.computeGraphWidth(),
      height: 150,
      frameColor: colors.frame,
      gridColor: colors.grid,
      horizontalMargin: 50,
    }

    this.pageViews = new PageViews(
      this.$('#participating-date-graph'),
      $.extend({}, this.graphOpts, {
        startDate: filter.get('startDate'),
        endDate: filter.get('endDate'),
        horizontalPadding: 15,
        barColor: colors.lightblue,
        participationColor: colors.darkblue,
      })
    )
    this.pageViews.graph(participations)

    this.categorizedPageViews = new CategorizedPageViews(
      this.$('#participating-category-graph'),
      $.extend({}, this.graphOpts, {
        bottomMargin: 25,
        barColor: colors.blue,
        strokeColor: colors.blue,
        sortBy: 'views',
      })
    )
    this.categorizedPageViews.graph(participations)

    this.gradeDistribution = new GradeDistribution(
      this.$('#grade-distribution-graph'),
      $.extend({}, this.graphOpts, {
        areaColor: colors.blue,
        strokeColor: colors.grid,
      })
    )
    return this.gradeDistribution.graph(filter.get('gradeDistribution'))
  }
}
