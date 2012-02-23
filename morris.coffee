# The original line graph.
#
window.Morris = {}
class window.Morris.Line

  # Initialise the graph.
  #
  # @param {string} id Target element's DOM ID
  # @param {Object} options
  constructor: (id, options) ->
    @el = $ document.getElementById(id)
    @options = $.extend @defaults, options
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
    marginTop: 25
    marginRight: 25
    marginBottom: 30
    marginLeft: 25
    numLines: 5
    gridLineColor: '#aaa'
    gridTextColor: '#888'
    gridTextSize: 12
    gridStrokeWidth: 0.5

  # Do any necessary pre-processing for a new dataset
  #
  precalc: ->
    # extract labels
    @xlabels = $.map @options.data, (d) => d[@options.xkey]
    @ylabels = @options.labels

    # extract series data
    @series = []
    for ykey in @options.ykeys
      @series.push $.map @options.data, (d) -> d[ykey]

    # translate x labels into nominal dates
    # note: currently using decimal years to specify dates
    @xvals = $.map @xlabels, (x) => @parseYear x
    @xmin = Math.min.apply null, @xvals
    @xmax = Math.max.apply null, @xvals
    if @xmin is @xmax
      @xmin -= 1
      @xmax += 1

    # use $.map to flatten arrays and find the max y value
    all_y_vals = $.map @series, (x) -> Math.max.apply null, x
    @ymax = Math.max(20, Math.max.apply(null, all_y_vals))

  # Clear and redraw the graph
  #
  redraw: ->
    # remove child elements (get rid of old drawings)
    @el.empty()

    # the raphael drawing instance
    @r = new Raphael(@el[0])

    # calculate grid dimensions
    left = @measureText(@ymax, @options.gridTextSize).width + @options.marginLeft
    width = @el.width() - left - @options.marginRight
    height = @el.height() - @options.marginTop - @options.marginBottom
    dx = width / (@xmax - @xmin)
    dy = height / @ymax

    # quick translation helpers
    transX = (x) =>
      if @xvals.length is 1
        left + width / 2
      else
       left + (x - @xmin) * dx
    transY = (y) =>
      return @options.marginTop + height - y * dy

    # draw y axis labels, horizontal lines
    lineInterval = height / (@options.numLines - 1)
    for i in [0..@options.numLines-1]
      y = @options.marginTop + i * lineInterval
      v = Math.round((@options.numLines - 1 - i) * @ymax / (@options.numLines - 1))
      @r.text(left - @options.marginLeft/2, y, v)
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
      label = @r.text(transX(i), @options.marginTop + height + @options.marginBottom / 2, i)
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
    hoverMargins = $.map columns.slice(1), (x, i) -> (x + columns[i]) / 2

  # create a path for a data series
  #
  createPath: (coords, top, left, bottom, right) ->
    path = ""
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

  parseYear: (year) ->
    m = year.toString().match /(\d+) Q(\d)/
    n = year.toString().match /(\d+)\-(\d+)/
    if m
      parseInt(m[1], 10) + (parseInt(m[2], 10) * 3 - 1) / 12
    else if n
      parseInt(n[1], 10) + (parseInt(n[2], 10) - 1) / 12
    else
      parseInt(year, 10)

