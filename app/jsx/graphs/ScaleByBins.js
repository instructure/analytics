define ->
  ##
  # Mixin for graphs to scale the x-axis by bins.
  ScaleByBins =

    ##
    # Max width of a bar, in pixels.
    maxBarWidth: 50

    ##
    # Minimum gutter between bars, as a percent of bar width.
    gutterPercent: 0.20

    ##
    # Given a number of bins (n) to place, determine:
    #
    #   @coverWidth: the width of a bin's cover (bar + minimal gutter), in pixels
    #   @barWidth: the width of a bin's bar, in pixels
    #   @binSpacing: the spacing from bin center to bin center, in pixels
    #   @x0: the x-coordinate of the center of the first bar, in pixels
    #
    # such that:
    #
    #   coverWidth = barWidth + a gutter (determined by @gutterPercent)
    #   the coverWidth regions around each bar are exclusive
    #   barWidth <= @maxBarWidth
    #   barWidth is otherwise maximized
    #   binSpacing spreads the bars over the full interior unless spread is false
    scaleByBins: (count, spread = true) ->
      interior = @width - @leftPadding - @rightPadding
      @coverWidth = Math.min((if count > 0 then interior / count else interior), @maxBarWidth * (1 + @gutterPercent))
      @barWidth = @coverWidth / (1 + @gutterPercent)
      if spread
        @binSpacing = if count > 1 then (interior - @barWidth) / (count - 1) else interior - @barWidth
        @x0 = @leftMargin + @leftPadding + @barWidth / 2
      else
        @binSpacing = @coverWidth
        @x0 = @leftMargin + @leftPadding + @coverWidth / 2

    ##
    # Calculate the x-coordinate, in pixels, for a bin.
    binX: (i) ->
      @x0 + i * @binSpacing
