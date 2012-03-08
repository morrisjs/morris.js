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
      @series.push $.map @options.data, (d) -> d[ykey]

    # translate x labels into nominal dates
    # note: currently using decimal years to specify dates
    if @options.parseTime
      @xvals = $.map @columnLabels, (x) => @parseYear x
    else
      @xvals = [(@columnLabels.length-1)..0]
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

  # Clear and redraw the graph
  #
  redraw: ->
    # remove child elements (get rid of old drawings)
    @el.empty()

    # the raphael drawing instance
    @r = new Raphael(@el[0])

    # calculate grid dimensions
    maxYLabelWidth = Math.max(
      @measureText(@options.ymin + @options.units, @options.gridTextSize).width,
      @measureText(@options.ymax + @options.units, @options.gridTextSize).width)
    left = maxYLabelWidth + @options.marginLeft
    width = @el.width() - left - @options.marginRight
    height = @el.height() - @options.marginTop - @options.marginBottom
    dx = width / (@xmax - @xmin)
    dy = height / (@options.ymax - @options.ymin)

    # quick translation helpers
    transX = (x) =>
      if @xvals.length is 1
        left + width / 2
      else
       left + (x - @xmin) * dx
    transY = (y) =>
      return @options.marginTop + height - (y - @options.ymin) * dy

    # draw y axis labels, horizontal lines
    yInterval = (@options.ymax - @options.ymin) / (@options.numLines - 1)
    firstY = Math.ceil(@options.ymin / yInterval) * yInterval
    lastY = Math.floor(@options.ymax / yInterval) * yInterval
    for lineY in [firstY..lastY] by yInterval
      v = Math.floor(lineY)
      y = transY(v)
      @r.text(left - @options.marginLeft/2, y, v + @options.units)
        .attr('font-size', @options.gridTextSize)
        .attr('fill', @options.gridTextColor)
        .attr('text-anchor', 'end')
      @r.path("M" + left + "," + y + 'H' + (left + width))
        .attr('stroke', @options.gridLineColor)
        .attr('stroke-width', @options.gridStrokeWidth)

    # draw x axis labels
    prevLabelMargin = null
    xLabelMargin = 50 # make this an option?
    for i in [Math.ceil(@xmin)..Math.floor(@xmax)]
      labelText = if @options.parseTime then i else @columnLabels[@columnLabels.length-i-1]
      label = @r.text(transX(i), @options.marginTop + height + @options.marginBottom / 2, labelText)
        .attr('font-size', @options.gridTextSize)
        .attr('fill', @options.gridTextColor)
      labelBox = label.getBBox()
      # ensure a minimum of `xLabelMargin` pixels between labels
      if prevLabelMargin is null or prevLabelMargin <= labelBox.x
        prevLabelMargin = labelBox.x + labelBox.width + xLabelMargin
      else
        label.remove()

    # draw the actual series
    columns = (transX(x) for x in @xvals)
    seriesCoords = []
    for s in @series
      seriesCoords.push($.map(s, (y, i) -> x: columns[i], y: transY(y)))
    for i in [seriesCoords.length-1..0]
      coords = seriesCoords[i]
      if coords.length > 1
        path = @createPath coords, @options.marginTop, left, @options.marginTop + height, left + width
        @r.path(path)
          .attr('stroke', @options.lineColors[i])
          .attr('stroke-width', @options.lineWidth)
    seriesPoints = ([] for i in [0..seriesCoords.length-1])
    for i in [seriesCoords.length-1..0]
      for c in seriesCoords[i]
        circle = @r.circle(c.x, c.y, @options.pointSize)
          .attr('fill', @options.lineColors[i])
          .attr('stroke-width', 1)
          .attr('stroke', '#ffffff')
        seriesPoints[i].push(circle)

    # hover labels
    hoverHeight = @options.hoverFontSize * 1.5 * (@series.length + 1)
    hover = @r.rect(-10, -hoverHeight / 2 - @options.hoverPaddingY, 20, hoverHeight + @options.hoverPaddingY * 2, 10)
      .attr('fill', @options.hoverFillColor)
      .attr('stroke', @options.hoverBorderColor)
      .attr('stroke-width', @options.hoverBorderWidth)
      .attr('opacity', @options.hoverOpacity)
    xLabel = @r.text(0, (@options.hoverFontSize * 0.75) - hoverHeight / 2, '')
      .attr('fill', @options.hoverLabelColor)
      .attr('font-weight', 'bold')
      .attr('font-size', @options.hoverFontSize)
    hoverSet = @r.set()
    hoverSet.push(hover)
    hoverSet.push(xLabel)
    yLabels = []
    for i in [0..@series.length-1]
      yLabel = @r.text(0, @options.hoverFontSize * 1.5 * (i + 1.5) - hoverHeight / 2, '')
        .attr('fill', @options.lineColors[i])
        .attr('font-size', @options.hoverFontSize)
      yLabels.push(yLabel)
      hoverSet.push(yLabel)
    updateHover = (index) =>
      hoverSet.show()
      xLabel.attr('text', @columnLabels[index])
      for i in [0..@series.length-1]
        yLabels[i].attr('text', "#{@seriesLabels[i]}: #{@commas(@series[i][index])}#{@options.units}")
      # recalculate hover box width
      maxLabelWidth = Math.max.apply null, $.map yLabels, (l) ->
        l.getBBox().width
      maxLabelWidth = Math.max maxLabelWidth, xLabel.getBBox().width
      hover.attr 'width', maxLabelWidth + @options.hoverPaddingX * 2
      hover.attr 'x', -@options.hoverPaddingX - maxLabelWidth / 2
      # move to y pos
      yloc = Math.min.apply null, $.map @series, (s) =>
        transY s[index]
      if yloc > hoverHeight + @options.hoverPaddingY * 2 + @options.hoverMargin + @options.marginTop
        yloc = yloc - hoverHeight / 2 - @options.hoverPaddingY - @options.hoverMargin
      else
        yloc = yloc + hoverHeight / 2 + @options.hoverPaddingY + @options.hoverMargin
      yloc = Math.max @options.marginTop + hoverHeight / 2 + @options.hoverPaddingY, yloc
      yloc = Math.min @options.marginTop + height - hoverHeight / 2 - @options.hoverPaddingY, yloc
      xloc = Math.min left + width - maxLabelWidth / 2 - @options.hoverPaddingX, columns[index]
      xloc = Math.max left + maxLabelWidth / 2 + @options.hoverPaddingX, xloc
      hoverSet.attr 'transform', "t#{xloc},#{yloc}"
    hideHover = ->
      hoverSet.hide()

    # column hilight
    hoverMargins = $.map columns.slice(1), (x, i) -> (x + columns[i]) / 2
    prevHilight = null
    pointGrow = Raphael.animation r: @options.pointSize + 3, 25, 'linear'
    pointShrink = Raphael.animation r: @options.pointSize, 25, 'linear'
    hilight = (index) =>
      if prevHilight isnt null and prevHilight isnt index
        for i in [0..seriesPoints.length-1]
          seriesPoints[i][prevHilight].animate pointShrink
      if index isnt null and prevHilight isnt index
        for i in [0..seriesPoints.length-1]
          seriesPoints[i][index].animate pointGrow
        updateHover index
      prevHilight = index
      if index is null
        hideHover()
    updateHilight = (x) =>
      x -= @el.offset().left
      for hoverIndex in [hoverMargins.length..0]
        if hoverIndex == 0 || hoverMargins[hoverIndex - 1] > x
          hilight hoverIndex
          break
    @el.mousemove (evt) =>
      updateHilight evt.pageX
    if @options.hideHover
      @el.mouseout (evt) =>
        hilight null
    touchHandler = (evt) =>
      touch = evt.originalEvent.touches[0] or evt.originalEvent.changedTouches[0]
      updateHilight touch.pageX
      return touch
    @el.bind 'touchstart', touchHandler
    @el.bind 'touchmove', touchHandler
    @el.bind 'touchend', touchHandler
    hilight(if @options.hideHover then null else 0)

  # create a path for a data series
  #
  createPath: (coords, top, left, bottom, right) ->
    path = ""
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

  measureText: (text, fontSize = 12) ->
    tt = @r.text(100, 100, text).attr('font-size', fontSize)
    ret = tt.getBBox()
    tt.remove()
    return ret

  parseYear: (date) ->
    s = date.toString()
    m = s.match /^(\d+) Q(\d)$/
    n = s.match /^(\d+)-(\d+)$/
    o = s.match /^(\d+)-(\d+)-(\d+)$/
    p = s.match /^(\d+) W(\d+)$/
    if m
      parseInt(m[1], 10) + (parseInt(m[2], 10) * 3 - 1) / 12
    else if p
      # calculate number of weeks in year given
      year = parseInt(p[1], 10);
      y1 = new Date(year, 0, 1);
      y2 = new Date(year+1, 0, 1);
      # first thursday in year (ISO 8601 standard)
      if y1.getDay() isnt 4
        y1.setMonth(0, 1 + ((4 - y1.getDay()) + 7) % 7);
      # first thursday in following year
      if y2.getDay() isnt 4
        y2.setMonth(0, 1 + ((4 - y2.getDay()) + 7) % 7);
      # Number of weeks between thursdays
      weeks = Math.ceil((y2 - y1) / 604800000);
      parseInt(p[1], 10) + (parseInt(p[2], 10) - 1) / weeks;
    else if n
      parseInt(n[1], 10) + (parseInt(n[2], 10) - 1) / 12
    else if o
      # parse to a timestamp
      year = parseInt(o[1], 10);
      month = parseInt(o[2], 10);
      day = parseInt(o[3], 10);
      timestamp = new Date(year, month - 1, day).getTime();
      # get timestamps for the beginning and end of the year
      y1 = new Date(year, 0, 1).getTime();
      y2 = new Date(year+1, 0, 1).getTime();
      # calculate a decimal-year value
      year + (timestamp - y1) / (y2 - y1);
    else
      parseInt(date, 10)

  # make long numbers prettier by inserting commas
  # eg: commas(1234567) -> '1,234,567'
  #
  commas: (num) ->
    ret = if num < 0 then "-" else ""
    ret + Math.abs(num).toFixed(0).replace(/(?=(?:\d{3})+$)(?!^)/g, ',')

window.Morris = Morris
# vim: set et ts=2 sw=2 sts=2
