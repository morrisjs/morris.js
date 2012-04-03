# The original line graph.
#
$ = jQuery

Morris = {}
class Morris.Line
  # Initialise the graph.
  #
  # @param {Object} options
  constructor: (options) ->
    if not (this instanceof Morris.Line)
      return new Morris.Line(options)
    if typeof options.element is 'string'
      @el = $ document.getElementById(options.element)
    else
      @el = $ options.element
    @options = $.extend {}, @defaults, options
    # bail if there's no data
    if @options.data is undefined or @options.data.length is 0
      return
    @el.addClass 'graph-initialised'
    @precalc()
    @redraw()

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
    ymax: 'auto'
    ymin: 'auto 0'
    marginTop: 25
    marginRight: 25
    marginBottom: 30
    marginLeft: 25
    numLines: 5
    gridLineColor: '#aaa'
    gridTextColor: '#888'
    gridTextSize: 12
    gridStrokeWidth: 0.5
    hoverPaddingX: 10
    hoverPaddingY: 5
    hoverMargin: 10
    hoverFillColor: '#fff'
    hoverBorderColor: '#ccc'
    hoverBorderWidth: 2
    hoverOpacity: 0.95
    hoverLabelColor: '#444'
    hoverFontSize: 12
    smooth: true
    hideHover: false
    parseTime: true
    units: ''
    dateFormat: (x) -> new Date(x).toString()
    xLabels: 'auto'
    xLabelsFormat: null

  # Do any necessary pre-processing for a new dataset
  #
  precalc: ->
    # sort data
    @options.data.sort (a, b) => (a[@options.xkey] < b[@options.xkey]) - (b[@options.xkey] < a[@options.xkey])
    # extract labels
    @columnLabels = $.map @options.data, (d) => d[@options.xkey]
    @seriesLabels = @options.labels

    # extract series data
    @series = []
    for ykey in @options.ykeys
      series_data = []
      for d in @options.data
        series_data.push(d[ykey])
      @series.push(series_data)

    # translate x labels into nominal dates
    # note: currently using decimal years to specify dates
    if @options.parseTime
      @xvals = $.map @columnLabels, (x) -> Morris.parseDate x
    else
      @xvals = [(@columnLabels.length-1)..0]
    # translate column labels, if they're timestamps
    if @options.parseTime
      @columnLabels = $.map @columnLabels, (d) =>
        if typeof d is 'number'
          @options.dateFormat(d)
        else
          d
    @xmin = Math.min.apply null, @xvals
    @xmax = Math.max.apply null, @xvals
    if @xmin is @xmax
      @xmin -= 1
      @xmax += 1

    # Compute the vertical range of the graph if desired
    if typeof @options.ymax is 'string' and @options.ymax[0..3] is 'auto'
      # use Array.concat to flatten arrays and find the max y value
      ymax = Math.max.apply null, Array.prototype.concat.apply([], @series)
      if @options.ymax.length > 5
        @options.ymax = Math.max parseInt(@options.ymax[5..], 10), ymax
      else
        @options.ymax = ymax
    if typeof @options.ymin is 'string' and @options.ymin[0..3] is 'auto'
      ymin = Math.min.apply null, Array.prototype.concat.apply([], @series)
      if @options.ymin.length > 5
        @options.ymin = Math.min parseInt(@options.ymin[5..], 10), ymin
      else
        @options.ymin = ymin

    # Some instance variables for later
    @pointGrow = Raphael.animation r: @options.pointSize + 3, 25, 'linear'
    @pointShrink = Raphael.animation r: @options.pointSize, 25, 'linear'
    @elementWidth = null
    @elementHeight = null
    # column hilight events
    @prevHilight = null
    @el.mousemove (evt) =>
      @updateHilight evt.pageX
    if @options.hideHover
      @el.mouseout (evt) =>
        @hilight null
    touchHandler = (evt) =>
      touch = evt.originalEvent.touches[0] or evt.originalEvent.changedTouches[0]
      @updateHilight touch.pageX
      return touch
    @el.bind 'touchstart', touchHandler
    @el.bind 'touchmove', touchHandler
    @el.bind 'touchend', touchHandler

  # Do any size-related calculations
  #
  calc: ->
    w = @el.width()
    h = @el.height()
    if @elementWidth != w or @elementHeight != h
      # calculate grid dimensions
      @maxYLabelWidth = Math.max(
        @measureText(@options.ymin + @options.units, @options.gridTextSize).width,
        @measureText(@options.ymax + @options.units, @options.gridTextSize).width)
      @left = @maxYLabelWidth + @options.marginLeft
      @width = @el.width() - @left - @options.marginRight
      @height = @el.height() - @options.marginTop - @options.marginBottom
      @dx = @width / (@xmax - @xmin)
      @dy = @height / (@options.ymax - @options.ymin)
      # calculate series data point coordinates
      @columns = (@transX(x) for x in @xvals)
      @seriesCoords = []
      for s in @series
        scoords = []
        $.each s, (i, y) =>
            if y == null
              scoords.push(null)
            else
              scoords.push(x: @columns[i], y: @transY(y))
        @seriesCoords.push(scoords)
      # calculate hover margins
      @hoverMargins = $.map @columns.slice(1), (x, i) => (x + @columns[i]) / 2

  # quick translation helpers
  #
  transX: (x) =>
    if @xvals.length is 1
      @left + @width / 2
    else
     @left + (x - @xmin) * @dx

  transY: (y) =>
    return @options.marginTop + @height - (y - @options.ymin) * @dy

  # Clear and redraw the graph
  #
  redraw: ->
    # remove child elements (get rid of old drawings)
    @el.empty()

    # the raphael drawing instance
    @r = new Raphael(@el[0])

    @calc()
    @drawGrid()
    @drawSeries()
    @drawHover()
    @hilight(if @options.hideHover then null else 0)

  # draw the grid, and axes labels
  #
  drawGrid: ->
    # draw y axis labels, horizontal lines
    yInterval = (@options.ymax - @options.ymin) / (@options.numLines - 1)
    firstY = Math.ceil(@options.ymin / yInterval) * yInterval
    lastY = Math.floor(@options.ymax / yInterval) * yInterval
    for lineY in [firstY..lastY] by yInterval
      v = Math.floor(lineY)
      y = @transY(v)
      @r.text(@left - @options.marginLeft/2, y, Morris.commas(v) + @options.units)
        .attr('font-size', @options.gridTextSize)
        .attr('fill', @options.gridTextColor)
        .attr('text-anchor', 'end')
      @r.path("M#{@left},#{y}H#{@left + @width}")
        .attr('stroke', @options.gridLineColor)
        .attr('stroke-width', @options.gridStrokeWidth)

    ## draw x axis labels
    ypos = @options.marginTop + @height + @options.marginBottom / 2
    xLabelMargin = 50 # make this an option?
    prevLabelMargin = null
    drawLabel = (labelText, xpos) =>
      label = @r.text(@transX(xpos), ypos, labelText)
        .attr('font-size', @options.gridTextSize)
        .attr('fill', @options.gridTextColor)
      labelBox = label.getBBox()
      # ensure a minimum of `xLabelMargin` pixels between labels
      if prevLabelMargin is null or prevLabelMargin <= labelBox.x
        prevLabelMargin = labelBox.x + labelBox.width + xLabelMargin
      else
        label.remove()
    if @options.parseTime
      if @columnLabels.length == 1 and @options.xLabels == 'auto'
        # where there's only one value in the series, we can't make a
        # sensible guess for an x labelling scheme, so just use the original
        # column label
        drawLabel(@columnLabels[0], @xvals[0])
      else
        for l in Morris.labelSeries(@xmin, @xmax, @width, @options.xLabels, @options.xLabelsFormat)
          drawLabel(l[0], l[1])
    else
      for i in [0..@columnLabels.length]
        labelText = @columnLabels[@columnLabels.length - i - 1]
        drawLabel(labelText, i)

  # draw the data series
  #
  drawSeries: ->
    for i in [@seriesCoords.length-1..0]
      coords = @seriesCoords[i]
      if coords.length > 1
        path = @createPath coords, @options.marginTop, @left, @options.marginTop + @height, @left + @width
        @r.path(path)
          .attr('stroke', @options.lineColors[i])
          .attr('stroke-width', @options.lineWidth)
    @seriesPoints = ([] for i in [0..@seriesCoords.length-1])
    for i in [@seriesCoords.length-1..0]
      for c in @seriesCoords[i]
        if c == null
          circle = null
        else
          circle = @r.circle(c.x, c.y, @options.pointSize)
            .attr('fill', @options.lineColors[i])
            .attr('stroke-width', 1)
            .attr('stroke', '#ffffff')
        @seriesPoints[i].push(circle)

  # create a path for a data series
  #
  createPath: (all_coords, top, left, bottom, right) ->
    path = ""
    coords = $.map(all_coords, (c) -> c)
    if @options.smooth
      grads = @gradients coords
      for i in [0..coords.length-1]
        c = coords[i]
        if i is 0
          path += "M#{c.x},#{c.y}"
        else
          g = grads[i]
          lc = coords[i - 1]
          lg = grads[i - 1]
          ix = (c.x - lc.x) / 4
          x1 = lc.x + ix
          y1 = Math.min(bottom, lc.y + ix * lg)
          x2 = c.x - ix
          y2 = Math.min(bottom, c.y - ix * g)
          path += "C#{x1},#{y1},#{x2},#{y2},#{c.x},#{c.y}"
    else
      path = "M" + $.map(coords, (c) -> "#{c.x},#{c.y}").join("L")
    return path

  # calculate a gradient at each point for a series of points
  #
  gradients: (coords) ->
    $.map coords, (c, i) ->
      if i is 0
        (coords[1].y - c.y) / (coords[1].x - c.x)
      else if i is (coords.length - 1)
        (c.y - coords[i - 1].y) / (c.x - coords[i - 1].x)
      else
        (coords[i + 1].y - coords[i - 1].y) / (coords[i + 1].x - coords[i - 1].x)

  # draw the hover tooltip
  #
  drawHover: ->
    # hover labels
    @hoverHeight = @options.hoverFontSize * 1.5 * (@series.length + 1)
    @hover = @r.rect(-10, -@hoverHeight / 2 - @options.hoverPaddingY, 20, @hoverHeight + @options.hoverPaddingY * 2, 10)
      .attr('fill', @options.hoverFillColor)
      .attr('stroke', @options.hoverBorderColor)
      .attr('stroke-width', @options.hoverBorderWidth)
      .attr('opacity', @options.hoverOpacity)
    @xLabel = @r.text(0, (@options.hoverFontSize * 0.75) - @hoverHeight / 2, '')
      .attr('fill', @options.hoverLabelColor)
      .attr('font-weight', 'bold')
      .attr('font-size', @options.hoverFontSize)
    @hoverSet = @r.set()
    @hoverSet.push(@hover)
    @hoverSet.push(@xLabel)
    @yLabels = []
    for i in [0..@series.length-1]
      yLabel = @r.text(0, @options.hoverFontSize * 1.5 * (i + 1.5) - @hoverHeight / 2, '')
        .attr('fill', @options.lineColors[i])
        .attr('font-size', @options.hoverFontSize)
      @yLabels.push(yLabel)
      @hoverSet.push(yLabel)

  updateHover: (index) =>
    @hoverSet.show()
    @xLabel.attr('text', @columnLabels[index])
    for i in [0..@series.length-1]
      @yLabels[i].attr('text', "#{@seriesLabels[i]}: #{Morris.commas(@series[i][index])}#{@options.units}")
    # recalculate hover box width
    maxLabelWidth = Math.max.apply null, $.map @yLabels, (l) ->
      l.getBBox().width
    maxLabelWidth = Math.max maxLabelWidth, @xLabel.getBBox().width
    @hover.attr 'width', maxLabelWidth + @options.hoverPaddingX * 2
    @hover.attr 'x', -@options.hoverPaddingX - maxLabelWidth / 2
    # move to y pos
    yloc = Math.min.apply null, $.map @series, (s) =>
      @transY s[index]
    if yloc > @hoverHeight + @options.hoverPaddingY * 2 + @options.hoverMargin + @options.marginTop
      yloc = yloc - @hoverHeight / 2 - @options.hoverPaddingY - @options.hoverMargin
    else
      yloc = yloc + @hoverHeight / 2 + @options.hoverPaddingY + @options.hoverMargin
    yloc = Math.max @options.marginTop + @hoverHeight / 2 + @options.hoverPaddingY, yloc
    yloc = Math.min @options.marginTop + @height - @hoverHeight / 2 - @options.hoverPaddingY, yloc
    xloc = Math.min @left + @width - maxLabelWidth / 2 - @options.hoverPaddingX, @columns[index]
    xloc = Math.max @left + maxLabelWidth / 2 + @options.hoverPaddingX, xloc
    @hoverSet.attr 'transform', "t#{xloc},#{yloc}"

  hideHover: ->
    @hoverSet.hide()

  hilight: (index) =>
    if @prevHilight isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @seriesPoints[i][@prevHilight]
          @seriesPoints[i][@prevHilight].animate @pointShrink
    if index isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @seriesPoints[i][index]
          @seriesPoints[i][index].animate @pointGrow
      @updateHover index
    @prevHilight = index
    if index is null
      @hideHover()

  updateHilight: (x) =>
    x -= @el.offset().left
    for hoverIndex in [@hoverMargins.length..0]
      if hoverIndex == 0 || @hoverMargins[hoverIndex - 1] > x
        @hilight hoverIndex
        break

  measureText: (text, fontSize = 12) ->
    tt = @r.text(100, 100, text).attr('font-size', fontSize)
    ret = tt.getBBox()
    tt.remove()
    return ret

# parse a date into a javascript timestamp
#
Morris.parseDate = (date) ->
  if typeof date is 'number'
    return date
  m = date.match /^(\d+) Q(\d)$/
  n = date.match /^(\d+)-(\d+)$/
  o = date.match /^(\d+)-(\d+)-(\d+)$/
  p = date.match /^(\d+) W(\d+)$/
  q = date.match /^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+)Z?$/
  r = date.match /^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+(\.\d+)?)Z?$/
  if m
    new Date(
      parseInt(m[1], 10),
      parseInt(m[2], 10) * 3 - 1,
      1).getTime()
  else if n
    new Date(
      parseInt(n[1], 10),
      parseInt(n[2], 10) - 1,
      1).getTime()
  else if o
    new Date(
      parseInt(o[1], 10),
      parseInt(o[2], 10) - 1,
      parseInt(o[3], 10)).getTime()
  else if p
    # calculate number of weeks in year given
    ret = new Date(parseInt(p[1], 10), 0, 1);
    # first thursday in year (ISO 8601 standard)
    if ret.getDay() isnt 4
      ret.setMonth(0, 1 + ((4 - ret.getDay()) + 7) % 7);
    # add weeks
    ret.getTime() + parseInt(p[2], 10) * 604800000
  else if q
    new Date(
      parseInt(q[1], 10),
      parseInt(q[2], 10) - 1,
      parseInt(q[3], 10),
      parseInt(q[4], 10),
      parseInt(q[5], 10)).getTime()
  else if r
    secs = parseFloat(r[6])
    isecs = Math.floor(secs)
    msecs = Math.round((secs - isecs) * 1000)
    new Date(
      parseInt(r[1], 10),
      parseInt(r[2], 10) - 1,
      parseInt(r[3], 10),
      parseInt(r[4], 10),
      parseInt(r[5], 10),
      isecs,
      msecs).getTime()
  else
    new Date(parseInt(date, 10), 0, 1).getTime()

# make long numbers prettier by inserting commas
# eg: commas(1234567) -> '1,234,567'
#
Morris.commas = (num) ->
  if num is null
    "n/a"
  else
    ret = if num < 0 then "-" else ""
    absnum = Math.abs(num)
    intnum = Math.floor(absnum).toFixed(0)
    ret += intnum.replace(/(?=(?:\d{3})+$)(?!^)/g, ',')
    strabsnum = absnum.toString()
    if strabsnum.length > intnum.length
      ret += strabsnum.slice(intnum.length)
    ret

# zero-pad numbers to two characters wide
#
Morris.pad2 = (number) -> (if number < 10 then '0' else '') + number

# generate a series of label, timestamp pairs for x-axis labels
#
Morris.labelSeries = (dmin, dmax, pxwidth, specName, xLabelsFormat) ->
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
  if xLabelsFormat
    spec.fmt = xLabelsFormat
  # calculate labels
  d = spec.start(d0)
  ret = []
  while  (t = d.getTime()) <= dmax
    if t >= dmin
      ret.push [spec.fmt(d), t]
    spec.incr(d)
  return ret

minutesSpecHelper = (interval) ->
  span: interval * 60 * 1000
  start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours())
  fmt: (d) -> "#{Morris.pad2(d.getHours())}:#{Morris.pad2(d.getMinutes())}"
  incr: (d) -> d.setMinutes(d.getMinutes() + interval)

secondsSpecHelper = (interval) ->
  span: interval * 1000
  start: (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes())
  fmt: (d) -> "#{Morris.pad2(d.getHours())}:#{Morris.pad2(d.getMinutes())}:#{Morris.pad2(d.getSeconds())}"
  incr: (d) -> d.setSeconds(d.getSeconds() + interval)

Morris.LABEL_SPECS =
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
  "year", "month", "day", "hour",
  "30min", "15min", "10min", "5min", "minute",
  "30sec", "15sec", "10sec", "5sec", "second"
]

window.Morris = Morris
# vim: set et ts=2 sw=2 sts=2
