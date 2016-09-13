class Morris.Line extends Morris.Grid
  # Initialise the graph.
  #
  constructor: (options) ->
    return new Morris.Line(options) unless (@ instanceof Morris.Line)
    super(options)

  init: ->
    # Some instance variables for later
    if @options.hideHover isnt 'always'
      @hover = new Morris.Hover(parent: @el)
      @on('hovermove', @onHoverMove)
      @on('hoverout', @onHoverOut)
      @on('gridclick', @onGridClick)

  # Default configuration
  #
  defaults:
    lineWidth: 3
    pointSize: 4
    lineColors: [
      '#0b62a4'
      '#7A92A3'
      '#4da74d'
      '#afd8f8'
      '#edc240'
      '#cb4b4b'
      '#9440ed'
    ]
    pointStrokeWidths: [1]
    pointStrokeColors: ['#ffffff']
    pointFillColors: []
    smooth: true
    shown: true
    xLabels: 'auto'
    xLabelFormat: null
    xLabelMargin: 24
    verticalGrid: false
    verticalGridHeight: 'full'
    verticalGridStartOffset: 0
    hideHover: false
    trendLine: false
    trendLineWidth: 2
    trendLineWeight: false
    trendLineColors: [
      '#689bc3'
      '#a2b3bf'
      '#64b764'
    ]

  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcPoints()
    @generatePaths()

  # calculate series data point coordinates
  #
  # @private
  calcPoints: ->
    for row in @data
      row._x = @transX(row.x)
      row._y = for y in row.y
        if y? then @transY(y) else y
      row._ymax = Math.min [@bottom].concat(y for y, i in row._y when y? and @hasToShow(i))...

  # hit test - returns the index of the row at the given x-coordinate
  #
  hitTest: (x) ->
    return null if @data.length == 0
    # TODO better search algo
    for r, index in @data.slice(1)
      break if x < (r._x + @data[index]._x) / 2
    index

  # click on grid event handler
  #
  # @private
  onGridClick: (x, y) =>
    index = @hitTest(x)
    @fire 'click', index, @data[index].src, x, y

  # hover movement event handler
  #
  # @private
  onHoverMove: (x, y) =>
    index = @hitTest(x)
    @displayHoverForRow(index)

  # hover out event handler
  #
  # @private
  onHoverOut: =>
    if @options.hideHover isnt false
      @displayHoverForRow(null)

  # display a hover popup over the given row
  #
  # @private
  displayHoverForRow: (index) ->
    if index?
      @hover.update(@hoverContentForRow(index)...)
      @hilight(index)
    else
      @hover.hide()
      @hilight()

  # hover content for a point
  #
  # @private
  hoverContentForRow: (index) ->
    row = @data[index]
    content = $("<div class='morris-hover-row-label'>").text(row.label)
    content = content.prop('outerHTML')
    for y, j in row.y
      if @options.labels[j] is false
        continue

      content += """
        <div class='morris-hover-point' style='color: #{@colorFor(row, j, 'label')}'>
          #{@options.labels[j]}:
          #{@yLabelFormat(y, j)}
        </div>
      """
    if typeof @options.hoverCallback is 'function'
      content = @options.hoverCallback(index, @options, content, row.src)
    [content, row._x, row._ymax]


  # generate paths for series lines
  #
  # @private
  generatePaths: ->
    @paths = for i in [0...@options.ykeys.length]
      smooth = if typeof @options.smooth is "boolean" then @options.smooth else @options.ykeys[i] in @options.smooth
      coords = ({x: r._x, y: r._y[i]} for r in @data when r._y[i] isnt undefined)

      if coords.length > 1
        Morris.Line.createPath coords, smooth, @bottom
      else
        null

  # Draws the line chart.
  #
  draw: ->
    @drawXAxis() if @options.axes in [true, 'both', 'x']
    @drawSeries()
    if @options.hideHover is false
      @displayHoverForRow(@data.length - 1)

  # draw the x-axis labels
  #
  # @private
  drawXAxis: ->
    # draw x axis labels
    ypos = @bottom + @options.padding / 2
    prevLabelMargin = null
    prevAngleMargin = null

    drawLabel = (labelText, xpos) =>
      label = @drawXAxisLabel(@transX(xpos), ypos, labelText)
      textBox = label.getBBox()
      label.transform("r#{-@options.xLabelAngle}")
      labelBox = label.getBBox()
      label.transform("t0,#{labelBox.height / 2}...")
      if @options.xLabelAngle != 0
        offset = -0.5 * textBox.width *
          Math.cos(@options.xLabelAngle * Math.PI / 180.0)
        label.transform("t#{offset},0...")
      # try to avoid overlaps
      labelBox = label.getBBox()
      if (not prevLabelMargin? or
          prevLabelMargin >= labelBox.x + labelBox.width or
          prevAngleMargin? and prevAngleMargin >= labelBox.x) and
          labelBox.x >= 0 and
          (labelBox.x + labelBox.width) < Morris.dimensions(@el).width
        if @options.xLabelAngle != 0
          margin = 1.25 * @options.gridTextSize /
            Math.sin(@options.xLabelAngle * Math.PI / 180.0)
          prevAngleMargin = labelBox.x - margin
        prevLabelMargin = labelBox.x - @options.xLabelMargin
        if @options.verticalGrid is true
          @drawVerticalGridLine(xpos)

      else
        label.remove()

    if @options.parseTime
      if @data.length == 1 and @options.xLabels == 'auto'
        # where there's only one value in the series, we can't make a
        # sensible guess for an x labelling scheme, so just use the original
        # column label
        labels = [[@data[0].label, @data[0].x]]
      else
        labels = Morris.labelSeries(@xmin, @xmax, @width, @options.xLabels, @options.xLabelFormat)
    else if @options.customLabels
      labels = ([row.label, row.x] for row in @options.customLabels)
    else
      labels = ([row.label, row.x] for row in @data)
    labels.reverse()
    for l in labels
      drawLabel(l[0], l[1])

    if typeof @options.verticalGrid is 'string'
      lines = Morris.labelSeries(@xmin, @xmax, @width, @options.verticalGrid)
      for l in lines
        @drawVerticalGridLine(l[1])

  # Draw a vertical grid line
  #
  # @private
  drawVerticalGridLine: (xpos) ->
    xpos = Math.floor(@transX(xpos)) + 0.5
    yStart = @yStart + @options.verticalGridStartOffset
    if @options.verticalGridHeight is 'full'
      yEnd = @yEnd
    else
      yEnd = @yStart - @options.verticalGridHeight
    @drawGridLine("M#{xpos},#{yStart}V#{yEnd}")

  # draw the data series
  #
  # @private
  drawSeries: ->
    @seriesPoints = []
    for i in [@options.ykeys.length-1..0]
      if @hasToShow(i)
        if @options.trendLine isnt false and
            @options.trendLine is true or @options.trendLine[i] is true
          @_drawTrendLine i

        @_drawLineFor i

    for i in [@options.ykeys.length-1..0]
      if @hasToShow(i)
        @_drawPointFor i

  _drawPointFor: (index) ->
    @seriesPoints[index] = []
    for row in @data
      circle = null
      if row._y[index]?
        circle = @drawLinePoint(row._x, row._y[index], @colorFor(row, index, 'point'), index)
      @seriesPoints[index].push(circle)

  _drawLineFor: (index) ->
    path = @paths[index]
    if path isnt null
      @drawLinePath path, @colorFor(null, index, 'line'), index

  _drawTrendLine: (index) ->
    # Least squares fitting for y = x * a + b
    sum_x = 0
    sum_y = 0
    sum_xx = 0
    sum_xy = 0
    datapoints = 0

    for val, i in @data
      x = val.x
      y = val.y[index]
      if y is undefined
        continue
      if @options.trendLineWeight is false
        weight = 1
      else
        weight = @options.data[i][@options.trendLineWeight]
      datapoints += weight

      sum_x += x * weight
      sum_y += y * weight
      sum_xx += x * x * weight
      sum_xy += x * y * weight

    a = (datapoints*sum_xy - sum_x*sum_y) / (datapoints*sum_xx - sum_x*sum_x)
    b = (sum_y / datapoints) - ((a * sum_x) / datapoints)

    data = [{}, {}]
    data[0].x = @transX(@data[0].x)
    data[0].y = @transY(@data[0].x * a + b)
    data[1].x = @transX(@data[@data.length - 1].x)
    data[1].y = @transY(@data[@data.length - 1].x * a + b)

    path = Morris.Line.createPath data, false, @bottom
    path = @raphael.path(path)
      .attr('stroke', @colorFor(null, index, 'trendLine'))
      .attr('stroke-width', @options.trendLineWidth)


  # create a path for a data series
  #
  # @private
  @createPath: (coords, smooth, bottom) ->
    path = ""
    grads = Morris.Line.gradients(coords) if smooth

    prevCoord = {y: null}
    for coord, i in coords
      if coord.y?
        if prevCoord.y?
          if smooth
            g = grads[i]
            lg = grads[i - 1]
            ix = (coord.x - prevCoord.x) / 4
            x1 = prevCoord.x + ix
            y1 = Math.min(bottom, prevCoord.y + ix * lg)
            x2 = coord.x - ix
            y2 = Math.min(bottom, coord.y - ix * g)
            path += "C#{x1},#{y1},#{x2},#{y2},#{coord.x},#{coord.y}"
          else
            path += "L#{coord.x},#{coord.y}"
        else
          if not smooth or grads[i]?
            path += "M#{coord.x},#{coord.y}"
      prevCoord = coord
    return path

  # calculate a gradient at each point for a series of points
  #
  # @private
  @gradients: (coords) ->
    grad = (a, b) -> (a.y - b.y) / (a.x - b.x)
    for coord, i in coords
      if coord.y?
        nextCoord = coords[i + 1] or {y: null}
        prevCoord = coords[i - 1] or {y: null}
        if prevCoord.y? and nextCoord.y?
          grad(prevCoord, nextCoord)
        else if prevCoord.y?
          grad(prevCoord, coord)
        else if nextCoord.y?
          grad(coord, nextCoord)
        else
          null
      else
        null

  # @private
  hilight: (index) =>
    if @prevHilight isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @hasToShow(i) and @seriesPoints[i][@prevHilight]
          @seriesPoints[i][@prevHilight].animate @pointShrinkSeries(i)
    if index isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @hasToShow(i) and @seriesPoints[i][index]
          @seriesPoints[i][index].animate @pointGrowSeries(i)
    @prevHilight = index

  colorFor: (row, sidx, type) ->
    if typeof @options.lineColors is 'function'
      @options.lineColors.call(@, row, sidx, type)
    else if type is 'point'
      @options.pointFillColors[sidx % @options.pointFillColors.length] || @options.lineColors[sidx % @options.lineColors.length]
    else if type is 'trendLine'
      @options.trendLineColors[sidx % @options.trendLineColors.length]
    else
      @options.lineColors[sidx % @options.lineColors.length]

  drawLinePath: (path, lineColor, lineIndex) ->
    @raphael.path(path)
      .attr('stroke', lineColor)
      .attr('stroke-width', @lineWidthForSeries(lineIndex))

  drawLinePoint: (xPos, yPos, pointColor, lineIndex) ->
    @raphael.circle(xPos, yPos, @pointSizeForSeries(lineIndex))
      .attr('fill', pointColor)
      .attr('stroke-width', @pointStrokeWidthForSeries(lineIndex))
      .attr('stroke', @pointStrokeColorForSeries(lineIndex))

  # @private
  pointStrokeWidthForSeries: (index) ->
    @options.pointStrokeWidths[index % @options.pointStrokeWidths.length]

  # @private
  pointStrokeColorForSeries: (index) ->
    @options.pointStrokeColors[index % @options.pointStrokeColors.length]

  # @private
  lineWidthForSeries: (index) ->
    if (@options.lineWidth instanceof Array)
      @options.lineWidth[index % @options.lineWidth.length]
    else
      @options.lineWidth

  # @private
  pointSizeForSeries: (index) ->
    if (@options.pointSize instanceof Array)
      @options.pointSize[index % @options.pointSize.length]
    else
      @options.pointSize

  # @private
  pointGrowSeries: (index) ->
    if @pointSizeForSeries(index) is 0
      return
    Raphael.animation r: @pointSizeForSeries(index) + 3, 25, 'linear'

  # @private
  pointShrinkSeries: (index) ->
    Raphael.animation r: @pointSizeForSeries(index), 25, 'linear'

# generate a series of label, timestamp pairs for x-axis labels
#
# @private
Morris.labelSeries = (dmin, dmax, pxwidth, specName, xLabelFormat) ->
  ddensity = 200 * (dmax - dmin) / pxwidth # seconds per `margin` pixels
  d0 = new Date(dmin)
  spec = Morris.LABEL_SPECS[specName]
  # if the spec doesn't exist, search for the closest one in the list
  if spec is undefined
    for name in Morris.AUTO_LABEL_ORDER
      s = Morris.LABEL_SPECS[name]
      if ddensity >= s.span
        spec = s
        break
  # if we run out of options, use second-intervals
  if spec is undefined
    spec = Morris.LABEL_SPECS["second"]
  # check if there's a user-defined formatting function
  if xLabelFormat
    spec = Morris.extend({}, spec, {fmt: xLabelFormat})
  # calculate labels
  d = spec.start(d0)
  ret = []
  while  (t = d.getTime()) <= dmax
    if t >= dmin
      ret.push [spec.fmt(d), t]
    spec.incr(d)
  return ret

# @private
minutesSpecHelper = (interval) ->
  span: interval * 60 * 1000
  start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours())
  fmt: (d) -> "#{Morris.pad2(d.getHours())}:#{Morris.pad2(d.getMinutes())}"
  incr: (d) -> d.setUTCMinutes(d.getUTCMinutes() + interval)

# @private
secondsSpecHelper = (interval) ->
  span: interval * 1000
  start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
  fmt: (d) -> "#{Morris.pad2(d.getHours())}:#{Morris.pad2(d.getMinutes())}:#{Morris.pad2(d.getSeconds())}"
  incr: (d) -> d.setUTCSeconds(d.getUTCSeconds() + interval)

Morris.LABEL_SPECS =
  "decade":
    span: 172800000000 # 10 * 365 * 24 * 60 * 60 * 1000
    start: (d) -> new Date(d.getFullYear() - d.getFullYear() % 10, 0, 1)
    fmt: (d) -> "#{d.getFullYear()}"
    incr: (d) -> d.setFullYear(d.getFullYear() + 10)
  "year":
    span: 17280000000 # 365 * 24 * 60 * 60 * 1000
    start: (d) -> new Date(d.getFullYear(), 0, 1)
    fmt: (d) -> "#{d.getFullYear()}"
    incr: (d) -> d.setFullYear(d.getFullYear() + 1)
  "month":
    span: 2419200000 # 28 * 24 * 60 * 60 * 1000
    start: (d) -> new Date(d.getFullYear(), d.getMonth(), 1)
    fmt: (d) -> "#{d.getFullYear()}-#{Morris.pad2(d.getMonth() + 1)}"
    incr: (d) -> d.setMonth(d.getMonth() + 1)
  "week":
    span: 604800000 # 7 * 24 * 60 * 60 * 1000
    start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate())
    fmt: (d) -> "#{d.getFullYear()}-#{Morris.pad2(d.getMonth() + 1)}-#{Morris.pad2(d.getDate())}"
    incr: (d) -> d.setDate(d.getDate() + 7)
  "day":
    span: 86400000 # 24 * 60 * 60 * 1000
    start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate())
    fmt: (d) -> "#{d.getFullYear()}-#{Morris.pad2(d.getMonth() + 1)}-#{Morris.pad2(d.getDate())}"
    incr: (d) -> d.setDate(d.getDate() + 1)
  "hour": minutesSpecHelper(60)
  "30min": minutesSpecHelper(30)
  "15min": minutesSpecHelper(15)
  "10min": minutesSpecHelper(10)
  "5min": minutesSpecHelper(5)
  "minute": minutesSpecHelper(1)
  "30sec": secondsSpecHelper(30)
  "15sec": secondsSpecHelper(15)
  "10sec": secondsSpecHelper(10)
  "5sec": secondsSpecHelper(5)
  "second": secondsSpecHelper(1)

Morris.AUTO_LABEL_ORDER = [
  "decade", "year", "month", "week", "day", "hour",
  "30min", "15min", "10min", "5min", "minute",
  "30sec", "15sec", "10sec", "5sec", "second"
]
