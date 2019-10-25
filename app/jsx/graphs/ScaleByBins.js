// #
// Mixin for graphs to scale the x-axis by bins.
export default {
  // #
  // Max width of a bar, in pixels.
  maxBarWidth: 50,

  // #
  // Minimum gutter between bars, as a percent of bar width.
  gutterPercent: 0.2,

  // #
  // Given a number of bins (n) to place, determine:
  //
  //   @coverWidth: the width of a bin's cover (bar + minimal gutter), in pixels
  //   @barWidth: the width of a bin's bar, in pixels
  //   @binSpacing: the spacing from bin center to bin center, in pixels
  //   @x0: the x-coordinate of the center of the first bar, in pixels
  //
  // such that:
  //
  //   coverWidth = barWidth + a gutter (determined by @gutterPercent)
  //   the coverWidth regions around each bar are exclusive
  //   barWidth <= @maxBarWidth
  //   barWidth is otherwise maximized
  //   binSpacing spreads the bars over the full interior unless spread is false
  scaleByBins(count, spread) {
    if (spread == null) spread = true
    const interior = this.width - this.leftPadding - this.rightPadding
    this.coverWidth = Math.min(
      count > 0 ? interior / count : interior,
      this.maxBarWidth * (1 + this.gutterPercent)
    )
    this.barWidth = this.coverWidth / (1 + this.gutterPercent)
    if (spread) {
      this.binSpacing =
        count > 1 ? (interior - this.barWidth) / (count - 1) : interior - this.barWidth
      return (this.x0 = this.leftMargin + this.leftPadding + this.barWidth / 2)
    } else {
      this.binSpacing = this.coverWidth
      return (this.x0 = this.leftMargin + this.leftPadding + this.coverWidth / 2)
    }
  },

  // #
  // Calculate the x-coordinate, in pixels, for a bin.
  binX(i) {
    return this.x0 + i * this.binSpacing
  }
}
