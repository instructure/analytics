define [
  'jquery'
  'vendor/graphael'
  'canvalytics/compiled/graphael_ext'
  'canvalytics/compiled/helpers'
  'jquery.ajaxJSON'
], ($, graphael, gext, helpers) ->

  rootObj =
    loadCourse: (course, users, loadedCb) ->

      participationCb = (data) ->

        callbackObj =
          drawAssignmentTardiness: (div_id, width, height, start, end) ->

          drawGrades: (div_id, width, height, start, end) ->

        loadedCb callbackObj

      $.ajaxJSON '/api/v1/analytics/assignments/courses/' + course.id,
          'GET', {user_ids: (user.id for user in users)}, participationCb
