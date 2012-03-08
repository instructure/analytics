require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/student_analytics_button'
], ($, template) ->

  {link, user_name} = ENV.ANALYTICS

  $('#right_nav').prepend template
    url: link
    label: "Student Analytics for #{user_name}"
