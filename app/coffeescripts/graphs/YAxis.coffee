define [
  'i18nObj'
], (I18n) ->
  class YAxis
    tickSize: 5

    constructor: (@host, opts={}) ->
      [@min, @max] = opts.range
      @style = opts.style ? 'default'
      @title = opts.title

      # scales for most graphs are multiples of 1 item. for percentage graphs
      # we start at 0.1%.
      scale = if @style is 'percent' then 0.001 else 1

      # choose the first step size from 1, 2, 5, 10, 20, 50, 100, etc. such
      # that 5 steps (scaled) exceeds or equals the size of the range. this
      # rate of growth "feels natural" and guarantees at least 2 labeled ticks
      # (at least 3 if ticks fall on both the min and max of the range) and at
      # most 6 (only 5 if either of the min or max are "off-tick")
      @tickStep = 1
      @labelFrequency = 1
      growth = [ 2, 2.5, 2 ]
      i = 0
      while @tickStep * scale * 5 < @max
        @tickStep *= growth[i % 3]
        i += 1

      # if the step size is at least 5 (and thus a multiple of 5), draw
      # five times as many ticks, but only label at the original rate (2 to 5
      # labels).
      if @tickStep > 1
        @tickStep /= 5
        @labelFrequency = 5

      # scale it down (or up)
      @tickStep *= scale

    ##
    # Convert a tick number to a value (assuming tick number 0 = value 0).
    tickValue: (tick) ->
      tick * @tickStep

    ##
    # Label every @labelFrequency-th tick with a label and grid line.
    draw: ->
      @width = 0

      j = Math.ceil @min / @tickStep
      while (value = @tickValue j) <= @max
        y = @host.valueY value
        if j % @labelFrequency is 0
          @line y
          @label y, @labelText value
        j += 1

      if @title
        @host.drawYLabel @title, offset: @width

    ##
    # Draw a grid line at y on the host, form left to right margin.
    line: (y) ->
      @host.paper.path([
        "M", @host.leftMargin, y,
        "l", @host.width, 0
      ]).attr stroke: @host.gridColor

    ##
    # Convert a value into a label.
    labelText: (value) ->
      if @style is 'percent'
        # scale up to percentage and add % character
        I18n.n(value * 100, { percentage: true })

      else
        # find power of 1000 to replace with suffix. we really shouldn't need
        # anything bigger than billion (B)
        power = Math.floor Math.log(value) / Math.log(1000)
        power = 0 if power < 0
        power = 3 if power > 3

        # get the correct suffix
        suffix = switch power
          when 0 then ''
          when 1 then 'k'
          when 2 then 'M'
          when 3 then 'B'

        # take out the power that'll be represented by the suffix and add the
        # suffix
        I18n.n(value / Math.pow(1000, power)) + suffix

    ##
    # Draw a y-axis label at y on the host, just outside the left margin.
    label: (y, text) ->
      label = @host.paper.text(@host.leftMargin - 5, y, text)
      label.attr
        fill: @host.frameColor
        'text-anchor': 'end'
      @width = Math.max(@width, label.getBBox().width)
