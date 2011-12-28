define ->
  obj =
    drawGrid: (r, x, y, w, h, dx, dy, color) ->
      line = (x1, y1, x2, y2) ->
        path = [
          "M", x1, y1,
          "L", x2, y2,
          "z"
        ].join(",")
        r.path(path).attr({stroke: color})

      i = 0
      while i <= w
        line x + i, y, x + i, y + h
        i += dx

      i = 0
      while i <= h
        line x, y + i, x + w, y + i
        i += dy
