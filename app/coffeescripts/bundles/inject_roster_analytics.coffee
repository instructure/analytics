# this will need to change once a td for the profile pic already exists (at
# that point we'll want to add the <a><img/></a> to that td below the
# profile pic, rather than making a new td. we'll also need to condition on
# profile pic column being present (the service may be disabled for that
# account))
require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/student_analytics_grid_button'
], ($, template) ->

  analytics = ENV.ANALYTICS
  for userId, link of analytics.student_links
    $("#user_#{userId}").prepend template url: link
