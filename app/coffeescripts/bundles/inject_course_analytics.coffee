require [
  'jquery'
  'analytics/jst/course_analytics_button'
], ($, template) ->
  if ENV.DRAFT_STATE
    $sidebar = $('#course_show_secondary .course-options')
  else
    $sidebar = $('#course_show_secondary .secondary-button-group')
  $sidebar.append template ENV.ANALYTICS
