require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/course_analytics_button'
], ($, template) ->

  $('#course_show_secondary').append template ENV.ANALYTICS
