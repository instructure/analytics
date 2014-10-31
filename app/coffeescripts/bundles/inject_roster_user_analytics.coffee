require [
  'jquery'
  'analytics/jst/student_analytics_button'
], ($, template) ->

  $('#right_nav').prepend template
    url: ENV.ANALYTICS.link