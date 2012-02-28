define [ 'jquery' ], ($) ->

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
      $tooltip.html @contents
      $tooltip.prepend $carat

    ##
    # Position the global tooltip elements for this Tooltip.
    position: ->
      dx = $tooltip.outerWidth() / 2
      dy = switch @direction
        when 'up' then $tooltip.outerHeight() + 11
        when 'down' then -11
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
