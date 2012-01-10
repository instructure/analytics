define [], () ->
  box = (x, base, width, lowerQ, median, upperQ, paper) ->
    [x, base, width, lowerQ, median, upperQ] = (Math.round arg for arg in [x, base, width, lowerQ, median, upperQ])
    path = ["M", x, base - lowerQ,
            "l", 0, lowerQ - upperQ,
            "l", width, 0,
            "l", 0, upperQ - lowerQ,
            "l", -width, 0,
            "m", 0, lowerQ - median,
            "l", width, 0,
            "z"]
    paper.path(path)

  whiskers = (x, base, width, max, min, paper) ->
    [x, base, width, max, min] = (Math.round arg for arg in [x, base, width, max, min])
    path = ["M", x, base - max,
            "l", width, 0,
            "m", -Math.round(width/2.0), 0,
            "l", 0, max - min,
            "m", -Math.round(width/2.0), 0,
            "l", width, 0,
            "z"]
    return paper.path(path)

  dataPoint = (x, base, width, value, paper) ->
    if value == null
      return paper.path("")

    [x, base, width, value] = (Math.round arg for arg in [x, base, width, value])
    return paper.circle(x + width/2, base - value, width / 4)

  (paper, x, y, width, height, values, opts) ->
    opts = opts || {}
    gutter = parseFloat(opts.gutter || "20%")
    total = Math.max.apply(Math, values)
    boxStroke = opts.boxStroke || "dimgray"
    boxFill = opts.boxFill || "lightgray"
    whiskerStroke = opts.whiskerStroke || "dimgray"
    valueStroke = opts.valueStroke || "dimgray"
    valueFillList = opts.valueFillList || ["red", "yellow", "yellow", "green"]

    total = []
    len = 0
    for i in [(values.length - 1)..0]
      total.push(Math.max.apply(Math, values[i]))
      len = Math.max(len, values[i].length)

    for i in [(values.length - 1)..0]
      if values[i].length < len
        for j in [(len - 1)..0]
          values[j].push(0)

    total = opts.total || Math.max.apply(Math, total)

    barwidth = width / (len * (100 + gutter) + gutter) * 100
    barhgutter = barwidth * gutter / 100
    barvgutter = if opts.vgutter? then opts.vgutter else 20
    X = x + barhgutter
    stack = []
    Y = (height - 2 * barvgutter) / total

    if !opts.stretch
      barhgutter = Math.round barhgutter
      barwidth = Math.floor barwidth

    for i in [0..(len-1)]
      stack = []
      min = values[0][i]*Y
      lowerQ = values[1][i]*Y
      median = values[2][i]*Y
      upperQ = values[3][i]*Y
      max = values[4][i]*Y
      val = if values[5][i] == null then null else values[5][i]*Y
      base = y + height - barvgutter
      bar = box(Math.round(X + barwidth / 2), base, barwidth, lowerQ, median, upperQ, paper).attr({stroke: boxStroke, fill: boxFill })
      whsk = whiskers(Math.round(X + barwidth / 2), base, barwidth, min, max, paper).attr({ stroke: whiskerStroke, fill: "none" })

      valueFillIndex = 0
      if val >= lowerQ
        valueFillIndex = 1
      if val >= median
        valueFillIndex = 2
      if val >= upperQ
        valueFillIndex = 3
      dp = dataPoint(Math.round(X + barwidth / 2), base, barwidth, val, paper).attr({stroke:valueStroke, fill:valueFillList[valueFillIndex]})

      X += barwidth
      X += barhgutter
