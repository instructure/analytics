require.config
  paths:
    analytics: "/plugins/analytics/javascripts"

require [
  'jquery'
  'analytics/jst/department_analytics_button'
], ($, template) ->

  # we want to put the button with the other "add user" and "add course"
  # buttons. however, the presence of those buttons is conditional. we can
  # detect them by looking for the rs-margin-all div they live in. if the div's
  # not there, we'll build it ourselves and put it where it should be.
  $sidebar = $('#right-side')
  $buttons = $('> div.rs-margin-all', $sidebar)
  $buttons ?= $('<div class="rs-margin-all">').appendTo $sidebar
  $buttons.append template ENV.ANALYTICS
