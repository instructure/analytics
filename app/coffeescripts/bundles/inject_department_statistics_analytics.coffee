require [
  'jquery'
  'analytics/jst/department_analytics_button'
], ($, template) ->

  # this page doesn't normally have a right sidebar. turn it on and add the
  # button to it.
  $('body').addClass 'with-right-side'
  $sidebar = $('#right-side')
  $buttons = $('> div.rs-margin-all', $sidebar)
  $buttons = $('<div class="rs-margin-top rs-margin-left rs-margin-right">').appendTo $sidebar
  $buttons.append template ENV.ANALYTICS
