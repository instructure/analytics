require [
  'jquery'
  'analytics/jst/student_analytics_button'
], ($, template) ->

  {link, student_name} = ENV.ANALYTICS

  $('#right_nav').prepend template
    url: link
    label: "Student Analytics for #{student_name}"
