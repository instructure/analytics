define [ 'jquery', 'str/htmlEscape' ], ($, htmlEscape) ->

  ##
  # Global shared tooltip elements. The $tooltip will be reused by each Tooltip
  # object we create (only one tooltip will ever be showing; javascript's mouse
  # model ensures the old cover's mouseout will fire before the new cover's
  # mouseover).
  $carat = $('<span class="ui-menu-carat"><span /></span>')
  $tooltip = $('<div class="analytics-tooltip" />')

  ##
  # Create a tooltip.
  class Tooltip
    constructor: (@reference, {@contents, @x, @y, @direction}) ->

    ##
    # Populate the global tooltip element with this Tooltip's info.
    populate: ->
      $tooltip.attr class: 'analytics-tooltip'
      switch @direction
        when 'up' then $tooltip.addClass('carat-bottom')
        when 'down' then $tooltip.addClass('carat-top')
        when 'left' then $tooltip.addClass('carat-right')
        when 'right' then $tooltip.addClass('carat-left')
      # can remove superfluous var and toString once xsspalooza lands in canvas
      contentsHtml = htmlEscape(@contents).toString()
      $tooltip.html contentsHtml
      $tooltip.prepend $carat

    ##
    # Position the global tooltip elements for this Tooltip.
    position: ->
      dx = switch @direction
        when 'up' then $tooltip.outerWidth() / 2
        when 'down' then $tooltip.outerWidth() / 2
        when 'left' then $tooltip.outerWidth() + 11
        when 'right' then -11

      dy = switch @direction
        when 'up' then $tooltip.outerHeight() + 11
        when 'down' then -11
        when 'left' then $tooltip.outerHeight() / 2
        when 'right' then $tooltip.outerHeight() / 2

      position = @reference.offset()
      position.left += Math.round(@x - dx)
      position.top += Math.round(@y - dy)
      $tooltip.offset position

    ##
    # Populate, attach to the document, and position the tooltip.
    show: =>
      @populate()
      $tooltip.appendTo document.body
      @position()

    ##
    # Remove the tooltip from the page until the next mouseover.
    hide: ->
      $tooltip.remove()
