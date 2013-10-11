require [
  'jquery'
  'analytics/jst/course_analytics_button'
], ($, template) ->
  $sidebar = $('#course_show_secondary .course-options')
  $sidebar.append template ENV.ANALYTICS
