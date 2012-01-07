define [
  'jquery'
  'vendor/graphael'
  'canvalytics/compiled/graphael_ext'
  'canvalytics/compiled/helpers'
  'jquery.ajaxJSON'
], ($, graphael, gext, helpers) ->

  PADDING = 5
  BAR_COLOR = "#4B7092"
  TARDINESS_WIDTH = 20
  GRID_COLOR = "#eee"
  ON_TIME_COLOR = "green"
  LATE_COLOR = "red"

  rootObj =
    loadCourse: (course, users, loadedCb) ->

      participationCb = (data) ->

        callbackObj =
          drawAssignmentTardiness: (div_id, width, height, start, end) ->
            start = helpers.dateToHours(start)
            end = helpers.dateToHours(end)
            r = graphael(div_id, width, height)

            graph_assignment = (time, on_time) ->
              time = helpers.dateToHours(time)
              position = (time - start) * (width - PADDING * 2 - TARDINESS_WIDTH) / (end - start) + PADDING + TARDINESS_WIDTH/2
              color = if on_time then ON_TIME_COLOR else LATE_COLOR
              r.rect(position, PADDING, TARDINESS_WIDTH, height - PADDING * 2).attr({fill: color, stroke: color})

            for assignment_id, assignment of data.assignments
              continue unless assignment.due_at && assignment.submission && assignment.submission.submitted_at
              due_at = Date.parse(assignment.due_at)
              submitted_at = Date.parse(assignment.submission.submitted_at)
              graph_assignment(due_at, submitted_at <= due_at)

            gext.drawGrid r, PADDING, PADDING, width - PADDING * 2,
                height - PADDING * 2, (width - PADDING * 2),
                (height - PADDING * 2), GRID_COLOR


          drawGrades: (div_id, width, height, start, end) ->

        loadedCb callbackObj

      $.ajaxJSON '/api/v1/analytics/assignments/courses/' + course.id,
          'GET', {user_ids: (user.id for user in users)}, participationCb
