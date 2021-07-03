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
    pointSizeGrow: 3
    lineColors: [
      '#2f7df6'
      '#53a351'
      '#f6c244'
      '#cb444a'
      '#4aa0b5'
      '#222529'
    ]
    extraClassLine: ''
    extraClassCircle: ''
    pointStrokeWidths: [1]
    pointStrokeColors: ['#ffffff']
    pointFillColors: []
    pointSuperimposed: true
    hoverOrdered: false
    hoverReversed: false
    smooth: true
    lineType: {}
    shown: true
    xLabels: 'auto'
    xLabelFormat: null
    xLabelMargin: 0
    verticalGrid: false
    verticalGridHeight: 'full'
    verticalGridStartOffset: 0
    verticalGridType: ''
    trendLine: false
    trendLineType: 'linear'
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
      row._y = for y, ii in row.y
        if ii < @options.ykeys.length - @options.nbYkeys2
          if y? then @transY(y) else y
      row._y2 = for y, ii in row.y
        if ii >= @options.ykeys.length - @options.nbYkeys2
          if y? then @transY2(y) else y
      row._ymax = Math.min [@bottom].concat(y for y, i in row._y when y? and @hasToShow(i))...
      row._ymax2 = Math.min [@bottom].concat(y for y, i in row._y2 when y? and @hasToShow(i))...

    for row, idx in @data
      @data[idx].label_x = []
      @data[idx].label_y = []
      for index in [@options.ykeys.length-1..0]
        if row._y[index]?
          @data[idx].label_x[index] = row._x
          @data[idx].label_y[index] = row._y[index] - 10

        if row._y2?
          if row._y2[index]?
            @data[idx].label_x[index] = row._x
            @data[idx].label_y[index] = row._y2[index] - 10

    if @options.pointSuperimposed is not true
      for row in @data
        for point,idx in row._y
          count = 0
          for v, i in row._y
            if point == v and typeof point is 'number' then count++
          if count > 1
            row._y[idx] = row._y[idx] + count * (this.lineWidthForSeries(idx))
            if this.lineWidthForSeries(idx) > 1 then row._y[idx] = row._y[idx] - 1

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

  escapeHTML:(string) =>
    map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;',
        "/": '&#x2F;',
    };
    reg = /[&<>"'/]/ig;
    return string.replace(reg, (match)=>(map[match]));

  # hover content for a point
  #
  # @private
  hoverContentForRow: (index) ->
    row = @data[index]
    content = ""

    order = []
    if @options.hoverOrdered is true
      for yy, jj in row.y
        max = null
        max_pos = -1
        for y, j in row.y
          if j not in order
            if max <= y || max is null
              max = y
              max_pos = j
        order.push(max_pos)
    else
      for yy, jj in row.y by -1
        order.push(jj)

    if @options.hoverReversed is true then order = order.reverse()

    axis = -1;
    for j in order by -1
      if @options.labels[j] is false
        continue

      if row.y[j] != undefined and axis == -1
        axis = j

      content = """
        <div class='morris-hover-point' style='color: #{@colorFor(row, j, 'label')}'>
          #{@options.labels[j]}:
          #{@yLabelFormat(row.y[j], j)}
        </div>
      """ + content

    content = "<div class='morris-hover-row-label'>"+@escapeHTML(row.label)+"</div>" + content

    if typeof @options.hoverCallback is 'function'
      content = @options.hoverCallback(index, @options, content, row.src)

    if axis > @options.nbYkeys2 then [content, row._x, row._ymax2]
    else [content, row._x, row._ymax]

  # generate paths for series lines
  #
  # @private
  generatePaths: ->
    @paths = for i in [0...@options.ykeys.length]
      # Keep 'smooth' option handling for compatibility
      smooth = if typeof @options.smooth is "boolean" then @options.smooth else @options.ykeys[i] in @options.smooth
      lineType = if smooth then 'smooth' else 'jagged'
      # Handle 'lineType' option
      if typeof @options.lineType is "string"
        lineType = @options.lineType
      else
        # Expect something like lineType: {"key1":"jagged","key2":"smooth","key3":"step","key4":"stepNoRiser",}
      if @options.lineType[@options.ykeys[i]] isnt undefined
        lineType = @options.lineType[@options.ykeys[i]]

      nb = @options.ykeys.length - @options.nbYkeys2
      if i < nb
        coords = ({x: r._x, y: r._y[i]} for r in @data when r._y[i] isnt undefined)
      else
        coords = ({x: r._x, y: r._y2[i]} for r in @data when r._y2[i] isnt undefined)

      if coords.length > 1
        Morris.Line.createPath coords, lineType, @bottom, i, @options.ykeys.length, @options.lineWidth
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
          labelBox.x >= 0 and (labelBox.x + labelBox.width) < Morris.dimensions(@el).width
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
    @drawGridLineVert("M#{xpos},#{yStart}V#{yEnd}")

  drawGridLineVert: (path) ->
    @raphael.path(path)
      .attr('stroke', @options.gridLineColor)
      .attr('stroke-width', @options.gridStrokeWidth)
      .attr('stroke-dasharray', @options.verticalGridType)

  # draw the data series
  #
  # @private
  drawSeries: ->
    @seriesPoints = []
    for i in [@options.ykeys.length-1..0]
      if @hasToShow(i)
        if @options.trendLine isnt false and
            @options.trendLine is true or @options.trendLine[i] is true
          if @data.length > 0
            @_drawTrendLine i

        @_drawLineFor i

    for i in [@options.ykeys.length-1..0]
      if @hasToShow(i)
        @_drawPointFor i

  _drawPointFor: (index) ->
    @seriesPoints[index] = []
    for row, idx in @data
      circle = null
      if row._y[index]?
        circle = @drawLinePoint(row._x, row._y[index], @colorFor(row, index, 'point'), index)

      if row._y2?
        if row._y2[index]?
          circle = @drawLinePoint(row._x, row._y2[index], @colorFor(row, index, 'point'), index)

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
    plots = []

    for val, i in @data
      x = val.x
      y = val.y[index]

      if y?
        plots.push([x,y])
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

    if @options.trendLineType != 'linear'
      if typeof regression is 'function'
        t_off_x = (@xmax - @xmin)/30
        data = []
        if @options.trendLineType == 'polynomial'
          reg = regression('polynomial', plots, 2);
          for i in [0..30]
            t_x = @xmin + i * t_off_x
            t_y = reg.equation[2] * t_x * t_x + reg.equation[1] * t_x + reg.equation[0]
            data.push({x: @transX(t_x), y: @transY(t_y)})

        else if @options.trendLineType == 'logarithmic'
          reg = regression('logarithmic', plots);
          for i in [0..30]
            t_x = @xmin + i * t_off_x
            t_y = reg.equation[0] + reg.equation[1] * Math.log(t_x)
            data.push({x: @transX(t_x), y: @transY(t_y)})

        else if @options.trendLineType == 'exponential'
          reg = regression('exponential', plots);
          for i in [0..30]
            t_x = @xmin + i * t_off_x
            t_y = reg.equation[0] + Math.exp(reg.equation[1] * t_x)
            data.push({x: @transX(t_x), y: @transY(t_y)})

        console.log('Regression formula is: '+reg.string+', r2:'+reg.r2)
      else
        console.log('Warning: regression() is undefined, please ensure that regression.js is loaded')

    if !isNaN(a)
      path = Morris.Line.createPath data, 'jagged', @bottom
      path = @raphael.path(path)
        .attr('stroke', @colorFor(null, index, 'trendLine'))
        .attr('stroke-width', @options.trendLineWidth)


  # create a path for a data series
  #
  # @private
  @createPath: (coords, lineType, bottom, index, nb, lineWidth) ->
    # index, nb and lineWidth are only used for lineType == 'vertical'

    path = ""
    grads = Morris.Line.gradients(coords) if lineType == 'smooth'

    prevCoord = {y: null}
    for coord, i in coords
      if coord.y?
        if prevCoord.y?
          if lineType == 'smooth'
            g = grads[i]
            lg = grads[i - 1]
            ix = (coord.x - prevCoord.x) / 4
            x1 = prevCoord.x + ix
            y1 = Math.min(bottom, prevCoord.y + ix * lg)
            x2 = coord.x - ix
            y2 = Math.min(bottom, coord.y - ix * g)
            path += "C#{x1},#{y1},#{x2},#{y2},#{coord.x},#{coord.y}"
          else if lineType == 'jagged'
            path += "L#{coord.x},#{coord.y}"
          else if  lineType == 'step'
            path += "L#{coord.x},#{prevCoord.y}"
            path += "L#{coord.x},#{coord.y}"
          else if  lineType == 'stepNoRiser'
            path += "L#{coord.x},#{prevCoord.y}"
            path += "M#{coord.x},#{coord.y}"
          else if  lineType == 'vertical'
            path += "L#{prevCoord.x-(nb-1)*(lineWidth/nb)+index*lineWidth},#{prevCoord.y}"
            path += "L#{prevCoord.x-(nb-1)*(lineWidth/nb)+index*lineWidth},#{bottom}"
            path += "M#{coord.x-(nb-1)*(lineWidth/nb)+index*lineWidth},#{bottom}"
            if (coords.length == (i+1))
              # Display the last vertical line
              path += "L#{coord.x-(nb-1)*(lineWidth/nb)+index*lineWidth},#{coord.y}"
              path += "L#{coord.x-(nb-1)*(lineWidth/nb)+index*lineWidth},#{bottom}"
        else
          if lineType != 'smooth' or grads[i]?
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
    if @options.animate
      straightPath = ''
      for row, ii in @data
        if straightPath == ''
          if lineIndex >= @options.ykeys.length - @options.nbYkeys2
            if row._y2[lineIndex]?
              straightPath = 'M'+row._x+','+@transY2(@ymin2)
          else if row._y[lineIndex]?
            if @options.lineType != 'vertical'
              straightPath = 'M'+row._x+','+@transY(@ymin)
            else
              straightPath = 'M'+row._x+','+@transY(0)+'L'+row._x+','+@transY(0)+'L'+row._x+','+@transY(0)
        else
          if lineIndex >= @options.ykeys.length - @options.nbYkeys2
            if row._y2[lineIndex]?
              straightPath += ','+row._x+','+@transY2(@ymin2)
              if @options.lineType == 'step' then straightPath += ','+row._x+','+@transY2(@ymin2)
          else if row._y[lineIndex]?
            if @options.lineType != 'vertical'
              straightPath += ','+row._x+','+@transY(@ymin)
            else
              row_x = row._x-(this.options.ykeys.length-1)*(this.options.lineWidth / this.options.ykeys.length)+lineIndex*this.options.lineWidth;
              straightPath += 'M'+row_x+','+@transY(0)+'L'+row_x+','+@transY(0)+'L'+row_x+','+@transY(0)
            if @options.lineType == 'step' then straightPath += ','+row._x+','+@transY(@ymin)

      rPath = @raphael.path(straightPath)
                      .attr('stroke', lineColor)
                      .attr('stroke-width', this.lineWidthForSeries(lineIndex))
                      .attr('class', @options.extraClassLine)
                      .attr('class', 'line_'+lineIndex)
      if @options.cumulative
        do (rPath, path) =>
          rPath.animate {path}, 600, '<>'
      else
        do (rPath, path) =>
          rPath.animate {path}, 500, '<>'
    else
      @raphael.path(path)
        .attr('stroke', lineColor)
        .attr('stroke-width', @lineWidthForSeries(lineIndex))
        .attr('class', @options.extraClassLine)
        .attr('class', 'line_'+lineIndex)

  drawLinePoint: (xPos, yPos, pointColor, lineIndex) ->
    @raphael.circle(xPos, yPos, @pointSizeForSeries(lineIndex))
      .attr('fill', pointColor)
      .attr('stroke-width', @pointStrokeWidthForSeries(lineIndex))
      .attr('stroke', @pointStrokeColorForSeries(lineIndex))
      .attr('class', @options.extraClassCircle)
      .attr('class', 'circle_line_'+lineIndex)

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
    Raphael.animation r: @pointSizeForSeries(index) + @options.pointSizeGrow, 25, 'linear'

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
