class Morris.Line extends Morris.Grid
  @include Morris.Hover
  
  # Initialise the graph.
  #
  constructor: (options) ->
    return new Morris.Line(options) unless (@ instanceof Morris.Line)
    super(options)

  init: ->
    # Some instance variables for later
    @pointGrow = Raphael.animation r: @options.pointSize + 3, 25, 'linear'
    @pointShrink = Raphael.animation r: @options.pointSize, 25, 'linear'
    
    @hoverConfigure @options.hoverOptions
    
    # column hilight events
    if @options.hilight
      @prevHilight = null
      @el.mousemove (evt) =>
        @updateHilight evt.pageX
      if @options.hilightAutoHide
        @el.mouseout (evt) =>
          @hilight null
      touchHandler = (evt) =>
        touch = evt.originalEvent.touches[0] or evt.originalEvent.changedTouches[0]
        @updateHilight touch.pageX
        return touch
      @el.bind 'touchstart', touchHandler
      @el.bind 'touchmove', touchHandler
      @el.bind 'touchend', touchHandler

  postInit: ->
    @hoverInit()

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
    pointWidths: [1]
    pointStrokeColors: ['#ffffff']
    pointFillColors: []
    smooth: true
    hilight: true
    hilightAutoHide: false
    xLabels: 'auto'
    xLabelFormat: null

  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcPoints()
    @hoverCalculateMargins()
    @generatePaths()
    @calcHilightMargins()

  # calculate series data point coordinates
  #
  # @private
  calcPoints: ->
    for row in @data
      row._x = @transX(row.x)
      row._y = for y in row.y
        if y? then @transY(y) else null

  # calculate hilight margins
  #
  # @private
  calcHilightMargins: ->
    @hilightMargins = ((r._x + @data[i]._x) / 2 for r, i in @data.slice(1))

  hoverCalculateMargins: ->
    @hoverMargins = ((r._x + @data[i]._x) / 2 for r, i in @data.slice(1))

  # generate paths for series lines
  #
  # @private
  generatePaths: ->
    @paths = for i in [0...@options.ykeys.length]
      smooth = @options.smooth is true or @options.ykeys[i] in @options.smooth
      coords = ({x: r._x, y: r._y[i]} for r in @data when r._y[i] isnt null)
      if coords.length > 1
        @createPath coords, smooth
      else
        null

  # Draws the line chart.
  #
  draw: ->
    @drawXAxis()
    @drawSeries()
    @hilight(if @options.hilightAutoHide then null else @data.length - 1) if @options.hilight

  # draw the x-axis labels
  #
  # @private
  drawXAxis: ->
    # draw x axis labels
    ypos = @bottom + @options.gridTextSize * 1.25
    xLabelMargin = 50 # make this an option?
    prevLabelMargin = null
    drawLabel = (labelText, xpos) =>
      label = @r.text(@transX(xpos), ypos, labelText)
        .attr('font-size', @options.gridTextSize)
        .attr('fill', @options.gridTextColor)
      labelBox = label.getBBox()
      # ensure a minimum of `xLabelMargin` pixels between labels, and ensure
      # labels don't overflow the container
      if (not prevLabelMargin? or prevLabelMargin >= labelBox.x + labelBox.width) and
          labelBox.x >= 0 and (labelBox.x + labelBox.width) < @el.width()
        prevLabelMargin = labelBox.x - xLabelMargin
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
    else
      labels = ([row.label, row.x] for row in @data)
    labels.reverse()
    for l in labels
      drawLabel(l[0], l[1])

  # draw the data series
  #
  # @private
  drawSeries: ->
    for i in [@options.ykeys.length-1..0]
      path = @paths[i]
      if path isnt null
        @r.path(path)
          .attr('stroke', @colorFor(row, i, 'line'))
          .attr('stroke-width', @options.lineWidth)
    @seriesPoints = ([] for i in [0...@options.ykeys.length])
    for i in [@options.ykeys.length-1..0]
      for row in @data
        if row._y[i] == null
          circle = null
        else
          circle = @r.circle(row._x, row._y[i], @options.pointSize)
            .attr('fill', @colorFor(row, i, 'point'))
            .attr('stroke-width', @strokeWidthForSeries(i))
            .attr('stroke', @strokeForSeries(i))
        @seriesPoints[i].push(circle)

  # create a path for a data series
  #
  # @private
  createPath: (coords, smooth) ->
    path = ""
    if smooth
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
          y1 = Math.min(@bottom, lc.y + ix * lg)
          x2 = c.x - ix
          y2 = Math.min(@bottom, c.y - ix * g)
          path += "C#{x1},#{y1},#{x2},#{y2},#{c.x},#{c.y}"
    else
      path = "M" + ("#{c.x},#{c.y}" for c in coords).join("L")
    return path

  # calculate a gradient at each point for a series of points
  #
  # @private
  gradients: (coords) ->
    for c, i in coords
      if i is 0
        (coords[1].y - c.y) / (coords[1].x - c.x)
      else if i is (coords.length - 1)
        (c.y - coords[i - 1].y) / (c.x - coords[i - 1].x)
      else
        (coords[i + 1].y - coords[i - 1].y) / (coords[i + 1].x - coords[i - 1].x)

  # @private
  hilight: (index) =>
    if @prevHilight isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @seriesPoints[i][@prevHilight]
          @seriesPoints[i][@prevHilight].animate @pointShrink
    if index isnt null and @prevHilight isnt index
      for i in [0..@seriesPoints.length-1]
        if @seriesPoints[i][index]
          @seriesPoints[i][index].animate @pointGrow
    @prevHilight = index

  # @private
  updateHilight: (x) =>
    x -= @el.offset().left
    for hilightIndex in [0...@hilightMargins.length]
      break if @hilightMargins[hilightIndex] > x
    @hilight hilightIndex

  # @private
  strokeWidthForSeries: (index) ->
    @options.pointWidths[index % @options.pointWidths.length]

  # @private
  strokeForSeries: (index) ->
    @options.pointStrokeColors[index % @options.pointStrokeColors.length]

  colorFor: (row, sidx, type) ->
    if typeof @options.lineColors is 'function'
      @options.lineColors.call(@, row, sidx, type)
    else if type is 'point'
      @options.pointFillColors[sidx % @options.pointFillColors.length] || @options.lineColors[sidx % @options.lineColors.length]
    else
      @options.lineColors[sidx % @options.lineColors.length]