require [
  'jquery'
  'analytics/jst/course_analytics_button'
], ($, template) ->
  $sidebar = $('#course_show_secondary .course-options')
  params = ENV.ANALYTICS
  $sidebar.append template params
