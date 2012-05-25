require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/course_analytics_button'
], ($, template) ->

  # we want to put the button with the other "top level" buttons. however, the
  # presence of those buttons is conditional. we can detect them by looking for
  # the rs-margin-bottom div they live in. if the div's not there, we'll build
  # it outselves and put it where it should be.
  $sidebar = $('#course_show_secondary')
  $buttons = $('> div:first', $sidebar)
  unless $buttons.hasClass('rs-margin-bottom')
    $buttons = $('<div class="rs-margin-lr rs-margin-top rs-margin-bottom">').prependTo $sidebar

  $buttons.append template ENV.ANALYTICS
