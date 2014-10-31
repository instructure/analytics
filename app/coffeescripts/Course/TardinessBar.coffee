define ['analytics/compiled/graphs/tooltip'], (Tooltip) ->

  ##
  # Draws a horizontal bar with layers representing the tardiness breakdown
  # (onTime, late, missing) of assignments for a specific student.
  class TardinessBar
    constructor: (@$el) ->
      @reset()

    ##
    # (Re)initialize with a fresh container and layer placement tracking.
    reset: ->
      @$el.empty()
      @paper = $('<span>').addClass('paper').appendTo(@$el)
      @left = 0
      @right = 100

      # attach tooltip that hangs below the bar when hovered
      @tooltip = new Tooltip @paper,
        x: 100
        y: 8
        direction: 'right'
      @paper.mouseover @tooltip.show
      @paper.mouseout @tooltip.hide

    ##
    # Calculate and add layers proportional to the count/total ratios in the
    # given data.
    show: (data) ->
      @tooltip.contents = "#{data.onTime} on time, #{data.late} late, #{data.missing} missing"
      @layer 'onTime', 100 * (data.onTime / data.total)
      @layer 'late', 100 * (data.late / data.total)
      @layer 'missing', 100 * (data.missing / data.total)

    ##
    # Add a layer to the bar of the given class ('onTime', 'late', or
    # 'missing') and width. Any previous layers should have updated internal so
    # that this layer starts 1px after the immediately preceding layer ended.
    layer: (klass, width) ->
      return unless width > 0
      $('<span>').addClass(klass).appendTo(@paper).css
        left: Math.round(@left) + '%'
        right: Math.round(@right - width) + '%'
        'border-left': if @left > 0 then '1px solid white' else 'none'
      @left += width
      @right -= width
