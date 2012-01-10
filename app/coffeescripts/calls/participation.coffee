define [
  'jquery'
  'vendor/graphael'
  'canvalytics/compiled/graphael_ext'
  'canvalytics/compiled/helpers'
  'jquery.ajaxJSON'
], ($, graphael, gext, helpers) ->

  PADDING = 5
  GRID_COLS = 1
  GRID_COLOR = "#eee"
  BAR_COLOR = "#4B7092"

  rootObj =
    loadCourse: (course, users, loadedCb) ->

      participationCb = (data) ->
        pageViewData = {}
        for date, counts of data["page_views"]
          days = helpers.dateToDays(Date.parse(date))
          pageViewData[days] = 0 unless pageViewData[days]?
          for action, count of counts
            pageViewData[days] = pageViewData[days] + count

        callbackObj =
          drawPageViews: (div_id, width, height, start, end) ->

            start = helpers.dateToDays(start)
            end = helpers.dateToDays(end)

            pageViewHistogram = []
            i = start
            max_count = 0
            while i < end
              count = 0
              count = pageViewData[i] if pageViewData[i]?
              max_count = count if count > max_count
              pageViewHistogram.push count
              i = i + 1

            r = graphael(div_id, width, height)

            rows = max_count
            rows = 1 if rows == 0
            gext.drawGrid r, PADDING, PADDING, width - PADDING * 2,
                height - PADDING * 2, (width - PADDING * 2)/GRID_COLS,
                (height - PADDING * 2)/rows, GRID_COLOR

            r.g.barchart PADDING, PADDING, width - PADDING * 2,
                height - PADDING * 2, [pageViewHistogram],
                {colors: [BAR_COLOR], gutter: "0%", vgutter: 0}

        loadedCb callbackObj

      $.ajaxJSON '/api/v1/analytics/participation/courses/' + course.id,
          'GET', {user_ids: (user.id for user in users)}, participationCb
