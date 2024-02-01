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
import {debounce, each, omit, groupBy} from 'lodash'
import Backbone from '@canvas/backbone'
import avatarPartial from '@canvas/avatar/jst/_avatar.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../views/jst/student_in_course.handlebars'
import PageViews from '../graphs/page_views'
import Responsiveness from '../graphs/responsiveness'
import AssignmentTardiness from '../graphs/assignment_tardiness'
import Grades from '../graphs/grades'
import colors from '../graphs/colors'
import StudentComboBox from './StudentComboBox'
import util from '../graphs/util'
import ActivitiesTable from '../components/ActivitiesTable'
import StudentSubmissionsTable from '../components/StudentSubmissionsTable'
import GradesTable from '../components/GradesTable'
import ResponsivenessTable from '../components/ResponsivenessTable'
import helpers from '../helpers'

const I18n = useI18nScope('student_in_course_view')

export default class StudentInCourseView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)

    const course = this.model.get('course')
    const student = this.model.get('student')
    const students = course.get('students')

    // build view
    this.$el = $(
      template({
        student: omit(student.toJSON(), 'html_url'),
        course: course.toJSON(),
      })
    )

    // cache elements for updates
    this.$crumb_span = $('#student_analytics_crumb span')
    this.$crumb_link = $('#student_analytics_crumb a')
    this.$student_link = this.$('.student_link')
    this.$current_score = this.$('.current_score')

    if (students.length > 1) {
      // build combobox of student names to replace name element
      this.comboBox = new StudentComboBox(this.model)
      this.$('.students_box').html(this.comboBox.$el)
    }

    // setup the graph objects
    this.setupGraphs()

    // render now and any time the model changes or the window resizes
    this.render()
    this.afterRender()
    this.model.on('change:student', () => {
      this.render()
      return this.afterRender()
    })
    return $(window).on(
      'resize',
      debounce(() => {
        const newWidth = util.computeGraphWidth()
        this.pageViews.resize({width: newWidth})
        this.responsiveness.resize({width: newWidth})
        this.assignmentTardiness.resize({width: newWidth})
        this.grades.resize({width: newWidth})
        this.render()
        return this.afterRender()
      }, 200)
    )
  }

  formatTableData(table) {
    let {data} = table

    if (data.bins != null || data.assignments != null) {
      data = data.bins ? data.bins : data.assignments
    }

    if (typeof table.format === 'function') {
      data = data.map(item => table.format(item))
    }

    if (table.div === '#responsiveness-table') {
      data = this.formatResponsivenessData(data)
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

  // #
  // This will get things into the proper format we need
  // for the responsiveness table. It produces an array
  // of objects in this format:
  // {
  //   date: Date
  //   instructorMessages: Number
  //   studentMessages: Number
  // }
  formatResponsivenessData(data) {
    const groups = groupBy(data, 'date')
    return Object.keys(groups).map(key => ({
      date: new Date(key),
      instructorMessages: groups[key].filter(obj => obj.track === 'instructor').length,
      studentMessages: groups[key].filter(obj => obj.track === 'student').length,
    }))
  }

  afterRender() {
    // render the table versions of the graphs for a11y/KO
    return this.renderTables([
      {
        div: '#participating-table',
        component: ActivitiesTable,
        data: this.model.get('student').get('participation'),
        sort(a, b) {
          return b.date - a.date
        },
      },
      {
        div: '#responsiveness-table',
        component: ResponsivenessTable,
        data: this.model.get('student').get('messaging'),
        sort(a, b) {
          return b.date - a.date
        },
      },
      {
        div: '#assignment-finishing-table',
        component: StudentSubmissionsTable,
        data: this.model.get('student').get('assignments'),
        format(assignment) {
          const formattedStatus = (() => {
            switch (assignment.original.status) {
              case 'late':
                return I18n.t('Late')
              case 'missing':
                return I18n.t('Missing')
              case 'on_time':
                return I18n.t('On Time')
              case 'floating':
                return I18n.t('Future')
            }
          })()

          return {
            title: assignment.title,
            dueAt: assignment.dueAt,
            submittedAt: assignment.submittedAt,
            status: formattedStatus,
            score: assignment.studentScore,
          }
        },
      },
      {
        div: '#grades-table',
        component: GradesTable,
        data: this.model.get('student').get('assignments'),
        format(assignment) {
          const scoreType =
            assignment.scoreDistribution != null
              ? assignment.studentScore >= assignment.scoreDistribution.median
                ? I18n.t('Good')
                : assignment.studentScore >= assignment.scoreDistribution.firstQuartile
                ? I18n.t('Fair')
                : I18n.t('Poor')
              : I18n.t('Good')

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
            student_score: assignment.studentScore,
            score_type: scoreType,
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

  // #
  // TODO: I18n
  render() {
    let message_url
    const course = this.model.get('course')
    const student = this.model.get('student')

    document.title = I18n.t('Analytics: %{course_code} -- %{student_name}', {
      course_code: course.get('course_code'),
      student_name: student.get('short_name'),
    })
    this.$crumb_span.text(student.get('short_name'))
    this.$crumb_link.attr({href: student.get('analytics_url')})

    this.$('.avatar').replaceWith(avatarPartial(omit(student.toJSON(), 'html_url')))
    this.$student_link.text(student.get('name'))
    this.$student_link.attr({href: student.get('html_url')})

    // hide message link unless url is present
    if ((message_url = student.get('message_student_url'))) {
      this.$('.message_student_link').show()
      this.$('.message_student_link').attr({href: message_url})
    } else {
      this.$('.message_student_link').hide()
    }

    const current_score = student.get('current_score')
    if (current_score !== null) {
      this.$current_score.text(`${current_score}%`)
    } else {
      this.$current_score.text('N/A')
    }

    const participation = student.get('participation')
    const messaging = student.get('messaging')
    const assignments = student.get('assignments')

    this.pageViews.graph(participation)
    this.responsiveness.graph(messaging)
    this.assignmentTardiness.graph(assignments)
    return this.grades.graph(assignments)
  }

  // #
  // Instantiate the graphs.
  setupGraphs() {
    // setup the graphs
    const graphOpts = {
      width: util.computeGraphWidth(),
      frameColor: colors.frame,
      gridColor: colors.grid,
      horizontalMargin: 40,
    }

    const dateGraphOpts = $.extend({}, graphOpts, {
      startDate: this.options.startDate,
      endDate: this.options.endDate,
      leftPadding: 30, // larger padding on left because of assymetrical
      rightPadding: 15,
    }) // responsiveness bubbles

    this.pageViews = new PageViews(
      this.$('#participating-graph'),
      $.extend({}, dateGraphOpts, {
        height: 150,
        barColor: colors.lightblue,
        participationColor: colors.darkblue,
      })
    )

    this.responsiveness = new Responsiveness(
      this.$('#responsiveness-graph'),
      $.extend({}, dateGraphOpts, {
        height: 110,
        verticalPadding: 4,
        gutterHeight: 32,
        markerWidth: 31,
        caratOffset: 7,
        caratSize: 10,
        studentColor: colors.orange,
        instructorColor: colors.blue,
      })
    )

    this.assignmentTardiness = new AssignmentTardiness(
      this.$('#assignment-finishing-graph'),
      $.extend({}, dateGraphOpts, {
        height: 250,
        colorOnTime: colors.sharpgreen,
        colorLate: colors.sharpyellow,
        colorMissing: colors.sharpred,
        colorUndated: colors.frame,
      })
    )

    this.grades = new Grades(
      this.$('#grades-graph'),
      $.extend({}, graphOpts, {
        height: 250,
        whiskerColor: colors.frame,
        boxColor: colors.grid,
        medianColor: colors.frame,
        colorGood: colors.sharpgreen,
        colorFair: colors.sharpyellow,
        colorPoor: colors.sharpred,
      })
    )
  }
}
