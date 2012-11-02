define [
  'jquery'
], ($) ->
  
  # we want to put the button with the other "add user" and "add course"
  # buttons. however, the presence of those buttons is conditional. we can
  # detect them by looking for the rs-margin-all div they live in. if the div's
  # not there, we'll build it ourselves and put it where it should be.
  inject: (html, $context) ->

    $buttons = $('> div.rs-margin-all', $context)
    if $buttons.length == 0
      $buttons = $('<div class="rs-margin-all">').appendTo $context

    $buttons.append html
  