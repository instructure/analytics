require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'I18n!analytics'
  'jquery'
  'analytics/jst/student_analytics_button'
], (I18n, $, template) ->

  {link, user_name} = ENV.ANALYTICS

  $('#right_nav').prepend template
    url: link
    label: I18n.t('button.student_analytics', "Student Analytics for %{user}", user: user_name)
