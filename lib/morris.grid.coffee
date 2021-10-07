class Morris.Grid extends Morris.EventEmitter
  # A generic pair of axes for line/area/bar charts.
  #
  # Draws grid lines and axis labels.
  #
  constructor: (options) ->
    # find the container to draw the graph in
    if typeof options.element is 'string'
      @el = document.getElementById(options.element)
    else
      @el = options.element[0] or options.element
    if not @el?
      throw new Error("Graph container element not found")

    if Morris.css(@el, 'position') == 'static'
      @el.style.position = 'relative'

    @options = Morris.extend {}, @gridDefaults, (@defaults || {}), options

    # backwards compatibility for units -> postUnits
    if typeof @options.units is 'string'
      @options.postUnits = options.units

    # the raphael drawing instance
    @raphael = new Raphael(@el)

    # some redraw stuff
    @elementWidth = null
    @elementHeight = null
    @dirty = false

    # range selection
    @selectFrom = null

    # more stuff
    @init() if @init

    # load data
    @setData @options.data

    # hover
    Morris.on @el, 'mousemove', @mousemoveHandler
    Morris.on @el, 'mouseleave', @mouseleaveHandler
    Morris.on @el, 'touchstart touchmove touchend', @touchHandler
    Morris.on @el, 'click', @clickHandler

    if @options.rangeSelect
      @selectionRect = @raphael.rect(0, 0, 0, Morris.innerDimensions(@el).height)
        .attr({ fill: @options.rangeSelectColor, stroke: false })
        .toBack()
        .hide()

      Morris.on @el, 'mousedown', @mousedownHandler

      Morris.on @el, 'mouseup', @mouseupHandler

    if @options.resize
      Morris.on window, 'resize', @resizeHandler

    # Disable tap highlight on iOS.
    @el.style.webkitTapHighlightColor = 'rgba(0,0,0,0)'

    @postInit() if @postInit

  # Default options
  #
  gridDefaults:
    dateFormat: null
    axes: true
    freePosition: false
    grid: true
    gridIntegers: false
    gridLineColor: '#aaa'
    gridStrokeWidth: 0.5
    gridTextColor: '#888'
    gridTextSize: 12
    gridTextFamily: 'sans-serif'
    gridTextWeight: 'normal'
    hideHover: 'auto'
    yLabelFormat: null
    yLabelAlign: 'right'
    yLabelAlign2: 'left'
    xLabelAngle: 0
    numLines: 5
    padding: 25
    parseTime: true
    postUnits: ''
    postUnits2: ''
    preUnits: ''
    preUnits2: ''
    ymax: 'auto'
    ymin: 'auto 0'
    ymax2: 'auto'
    ymin2: 'auto 0'
    regions: []
    regionsColors: ['#fde4e4']
    goals: []
    goals2: []
    goalStrokeWidth: 1.0
    goalStrokeWidth2: 1.0
    goalLineColors: [
      'red'
    ]
    goalLineColors2: [
      'red'
    ]
    events: []
    eventStrokeWidth: 1.0
    eventLineColors: [
      '#005a04'
    ]
    rangeSelect: null
    rangeSelectColor: '#eef'
    resize: true,
    dataLabels: true,
    dataLabelsPosition: 'outside',
    dataLabelsFamily: 'sans-serif',
    dataLabelsSize: 12,
    dataLabelsWeight: 'normal',
    dataLabelsColor: 'auto',
    animate: true
    nbYkeys2: 0
    smooth: true

  # Destroy
  #
  destroy: () ->
    Morris.off @el, 'mousemove', @mousemoveHandler
    Morris.off @el, 'mouseleave', @mouseleaveHandler
    Morris.off @el, 'touchstart touchmove touchend', @touchHandler
    Morris.off @el, 'click', @clickHandler
    if @options.rangeSelect
      Morris.off @el, 'mousedown', @mousedownHandler
      Morris.off @el, 'mouseup', @mouseupHandler

    if @options.resize
      window.clearTimeout @timeoutId
      Morris.off window, 'resize', @resizeHandler

  # Update the data series and redraw the chart.
  #
  setData: (data, redraw = true) ->

    @options.data = data

    if !data? or data.length == 0
      @data = []
      @raphael.clear()
      @hover.hide() if @hover?
      return

    ymax = if @cumulative then 0 else null
    ymin = if @cumulative then 0 else null
    ymax2 = if @cumulative then 0 else null
    ymin2 = if @cumulative then 0 else null

    if @options.goals.length > 0
      minGoal = Math.min @options.goals...
      maxGoal = Math.max @options.goals...
      ymin = if ymin? then Math.min(ymin, minGoal) else minGoal
      ymax = if ymax? then Math.max(ymax, maxGoal) else maxGoal

    if @options.goals2.length > 0
      minGoal = Math.min @options.goals2...
      maxGoal = Math.max @options.goals2...
      ymin2 = if ymin2? then Math.min(ymin2, minGoal) else minGoal
      ymax2 = if ymax2? then Math.max(ymax2, maxGoal) else maxGoal

    if @options.nbYkeys2 > @options.ykeys.length then @options.nbYkeys2 = @options.ykeys.length

    @data = for row, index in data
      ret = {src: row}

      ret.label = row[@options.xkey]
      if @options.parseTime
        ret.x = Morris.parseDate(ret.label)
        if @options.dateFormat
          ret.label = @options.dateFormat ret.x
        else if typeof ret.label is 'number'
          ret.label = new Date(ret.label).toString()
      else if @options.freePosition
        ret.x = parseFloat(row[@options.xkey])
        if @options.xLabelFormat
          ret.label = @options.xLabelFormat ret
      else
        ret.x = index
        if @options.xLabelFormat
          ret.label = @options.xLabelFormat ret
      total = 0
      ret.y = for ykey, idx in @options.ykeys
        yval = row[ykey]
        yval = parseFloat(yval) if typeof yval is 'string'
        yval = null if yval? and typeof yval isnt 'number'
        if idx < @options.ykeys.length - @options.nbYkeys2
          if yval? and @hasToShow(idx)
            if @cumulative
              if total < 0 and yval > 0
                total = yval
              else
                total += yval
            else
              if ymax?
                ymax = Math.max(yval, ymax)
                ymin = Math.min(yval, ymin)
              else
                ymax = ymin = yval
          if @cumulative and total?
            ymax = Math.max(total, ymax)
            ymin = Math.min(total, ymin)
        else
          if yval? and @hasToShow(idx)
            if @cumulative
              total = yval
            else
              if ymax2?
                ymax2 = Math.max(yval, ymax2)
                ymin2 = Math.min(yval, ymin2)
              else
                ymax2 = ymin2 = yval
          if @cumulative and total?
            ymax2 = Math.max(total, ymax2)
            ymin2 = Math.min(total, ymin2)
        yval
      ret

    if @options.parseTime or @options.freePosition
      @data = @data.sort (a, b) -> (a.x > b.x) - (b.x > a.x)

    # calculate horizontal range of the graph
    @xmin = @data[0].x
    @xmax = @data[@data.length - 1].x

    @events = []
    if @options.events.length > 0
      if @options.parseTime
        for e in @options.events
          if e instanceof Array
            [from, to] = e
            @events.push([Morris.parseDate(from), Morris.parseDate(to)])
          else
            @events.push(Morris.parseDate(e))
      else
        @events = @options.events
      flatEvents = @events.map (e) -> e
      @xmax = Math.max(@xmax, Math.max(flatEvents...))
      @xmin = Math.min(@xmin, Math.min(flatEvents...))

    if @xmin is @xmax
      @xmin -= 1
      @xmax += 1

    @ymin = @yboundary('min', ymin)
    @ymax = @yboundary('max', ymax)
    @ymin2 = @yboundary('min2', ymin2)
    @ymax2 = @yboundary('max2', ymax2)

    if @ymin is @ymax
      @ymin -= 1 if ymin
      @ymax += 1

    if @ymin2 is @ymax2
      @ymin2 -= 1 if ymin2
      @ymax2 += 1

    if @options.axes in [true, 'both', 'y'] or @options.grid is true
      if (@options.ymax == @gridDefaults.ymax and
          @options.ymin == @gridDefaults.ymin)
        # calculate 'magic' grid placement
        @grid = @autoGridLines(@ymin, @ymax, @options.numLines)
        @ymin = Math.min(@ymin, @grid[0])
        @ymax = Math.max(@ymax, @grid[@grid.length - 1])
      else
        step = (@ymax - @ymin) / (@options.numLines - 1)

        if @options.gridIntegers
          step = Math.max(1, Math.round(step));

        @grid = for y in [@ymin..@ymax] by step
          parseFloat(y.toFixed(2))

      if (@options.ymax2 == @gridDefaults.ymax2 and
          @options.ymin2 == @gridDefaults.ymin2 and
          @options.nbYkeys2 > 0)
        # calculate 'magic' grid placement
        @grid2 = @autoGridLines(@ymin2, @ymax2, @options.numLines)
        @ymin2 = Math.min(@ymin2, @grid2[0])
        @ymax2 = Math.max(@ymax2, @grid2[@grid2.length - 1])
      else
        step2 = (@ymax2 - @ymin2) / (@options.numLines - 1)
        @grid2 = for y in [@ymin2..@ymax2] by step2
          parseFloat(y.toFixed(2))

    @dirty = true
    @redraw() if redraw

  yboundary: (boundaryType, currentValue) ->
    boundaryOption = @options["y#{boundaryType}"]
    if typeof boundaryOption is 'string'
      if boundaryOption[0..3] is 'auto'
        if boundaryOption.length > 5
          suggestedValue = parseInt(boundaryOption[5..], 10)
          return suggestedValue unless currentValue?
          Math[boundaryType.substring(0,3)](currentValue, suggestedValue)
        else
          if currentValue? then currentValue else 0
      else
        parseInt(boundaryOption, 10)
    else
      boundaryOption

  autoGridLines: (ymin, ymax, nlines) ->
    span = ymax - ymin
    ymag = Math.floor(Math.log(span) / Math.log(10))
    unit = Math.pow(10, ymag)

    # calculate initial grid min and max values
    gmin = Math.floor(ymin / unit) * unit
    gmax = Math.ceil(ymax / unit) * unit
    step = (gmax - gmin) / (nlines - 1)
    if unit == 1 and step > 1 and Math.ceil(step) != step
      step = Math.ceil(step)
      gmax = gmin + step * (nlines - 1)

    # ensure zero is plotted where the range includes zero
    if gmin < 0 and gmax > 0
      gmin = Math.floor(ymin / step) * step
      gmax = Math.ceil(ymax / step) * step

    # special case for decimal numbers
    if step < 1
      smag = Math.floor(Math.log(step) / Math.log(10))
      grid = for y in [gmin..gmax] by step
        parseFloat(y.toFixed(1 - smag))
    else
      grid = (y for y in [gmin..gmax] by step)
    grid

  _calc: ->
    {width:w, height:h} = Morris.dimensions @el

    if @elementWidth != w or @elementHeight != h or @dirty
      @elementWidth = w
      @elementHeight = h
      @dirty = false
      # recalculate grid dimensions
      @left = @options.padding
      @right = @elementWidth - @options.padding
      @top = @options.padding
      @bottom = @elementHeight - @options.padding
      if @options.axes in [true, 'both', 'y']
        if @grid?
          yLabelWidths = for gridLine in @grid
            @measureText(@yAxisFormat(gridLine)).width

        if @options.nbYkeys2 > 0
          yLabelWidths2 = for gridLine in @grid2
            @measureText(@yAxisFormat2(gridLine)).width

        if not @options.horizontal
          @left += Math.max(yLabelWidths...)
          if @options.nbYkeys2 > 0
            @right -= Math.max(yLabelWidths2...)
        else
          @bottom -= @options.padding / 2

      if @options.axes in [true, 'both', 'x']
        if not @options.horizontal
          angle = -@options.xLabelAngle
        else
          angle = -90

        bottomOffsets = for i in [0...@data.length]
          @measureText(@data[i].label, angle).height

        if not @options.horizontal
          @bottom -= Math.max(bottomOffsets...)
        else
          @left += Math.max(bottomOffsets...)

      @width = Math.max(1, @right - @left)
      @height = Math.max(1, @bottom - @top)

      if not @options.horizontal
        @dx = @width / (@xmax - @xmin)
        @dy = @height / (@ymax - @ymin)
        @dy2 = @height / (@ymax2 - @ymin2)

        @yStart = @bottom
        @yEnd = @top
        @xStart = @left
        @xEnd = @right

        @xSize = @width
        @ySize = @height
      else
        @dx = @height / (@xmax - @xmin)
        @dy = @width / (@ymax - @ymin)
        @dy2 = @width / (@ymax2 - @ymin2)

        @yStart = @left
        @yEnd = @right
        @xStart = @top
        @xEnd = @bottom

        @xSize = @height
        @ySize = @width

      @calc() if @calc

  # Quick translation helpers
  #
  transY: (y) ->
    if not @options.horizontal
      @bottom - (y - @ymin) * @dy
    else
      @left + (y - @ymin) * @dy
  transY2: (y) ->
    if not @options.horizontal
      @bottom - (y - @ymin2) * @dy2
    else
      @left + (y - @ymin2) * @dy2
  transX: (x) ->
    if @data.length == 1
      (@xStart + @xEnd) / 2
    else
      @xStart + (x - @xmin) * @dx


  # Draw it!
  #
  # If you need to re-size your charts, call this method after changing the
  # size of the container element.
  redraw: ->
    @raphael.clear()
    @_calc()
    @drawGrid()
    @drawRegions()
    @drawEvents()
    @draw() if @draw
    @drawGoals()
    @setLabels()

  # @private
  #
  measureText: (text, angle = 0) ->
    tt = @raphael.text(100, 100, text)
      .attr('font-size', @options.gridTextSize)
      .attr('font-family', @options.gridTextFamily)
      .attr('font-weight', @options.gridTextWeight)
      .rotate(angle)
    ret = tt.getBBox()
    tt.remove()
    ret

  # @private
  #
  yAxisFormat: (label) -> @yLabelFormat(label, 0)
  yAxisFormat2: (label) -> @yLabelFormat(label, 1000)

  # @private
  #
  yLabelFormat: (label, i) ->
    if typeof @options.yLabelFormat is 'function'
      @options.yLabelFormat(label, i)
    else
      if @options.nbYkeys2 == 0 || (i <= @options.ykeys.length - @options.nbYkeys2 - 1)
        "#{@options.preUnits}#{Morris.commas(label)}#{@options.postUnits}"
      else
        "#{@options.preUnits2}#{Morris.commas(label)}#{@options.postUnits2}"

  yLabelFormat_noUnit: (label, i) ->
    if typeof @options.yLabelFormat is 'function'
      @options.yLabelFormat(label, i)
    else
      "#{Morris.commas(label)}"

  # get the X position of a label on the Y axis
  #
  # @private
  getYAxisLabelX: ->
    if @options.yLabelAlign is 'right'
      @left - @options.padding / 2
    else
      @options.padding / 2


  # draw y axis labels, horizontal lines
  #
  drawGrid: ->
    return if @options.grid is false and @options.axes not in [true, 'both', 'y']

    if not @options.horizontal
      basePos = @getYAxisLabelX()
      basePos2 = @right + @options.padding / 2
    else
      basePos = @getXAxisLabelY()
      basePos2 = @top - (@options.xAxisLabelTopPadding || @options.padding / 2)

    if @grid?
      for lineY in @grid
        pos = @transY(lineY)
        if @options.axes in [true, 'both', 'y']
          if not @options.horizontal
            @drawYAxisLabel(basePos, pos, @yAxisFormat(lineY), 1)
          else
            @drawXAxisLabel(pos, basePos, @yAxisFormat(lineY))

        if @options.grid
          pos = Math.floor(pos) + 0.5
          if not @options.horizontal
            if isNaN(@xEnd)
              @xEnd = 20
            @drawGridLine("M#{@xStart},#{pos}H#{@xEnd}")
          else
            @drawGridLine("M#{pos},#{@xStart}V#{@xEnd}")

    if @options.nbYkeys2 > 0
      for lineY in @grid2
        pos = @transY2(lineY)
        if @options.axes in [true, 'both', 'y']
          if not @options.horizontal
            @drawYAxisLabel(basePos2, pos, @yAxisFormat2(lineY), 2)
          else
            @drawXAxisLabel(pos, basePos2, @yAxisFormat2(lineY))

  # draw horizontal regions
  #
  drawRegions: ->
    for region, i in @options.regions
      color = @options.regionsColors[i % @options.regionsColors.length]
      @drawRegion(region, color)

  # draw goals horizontal lines
  #
  drawGoals: ->
    for goal, i in @options.goals
      color = @options.goalLineColors[i % @options.goalLineColors.length]
      @drawGoal(goal, color)

    for goal, i in @options.goals2
      color = @options.goalLineColors2[i % @options.goalLineColors2.length]
      @drawGoal2(goal, color)

  # draw events vertical lines
  drawEvents: ->
    if @events?
      for event, i in @events
        color = @options.eventLineColors[i % @options.eventLineColors.length]
        @drawEvent(event, color)

  drawGoal: (goal, color) ->
    y = Math.floor(@transY(goal)) + 0.5
    if not @options.horizontal
      path = "M#{@xStart},#{y}H#{@xEnd}"
    else
      path = "M#{y},#{@xStart}V#{@xEnd}"

    @raphael.path(path)
      .attr('stroke', color)
      .attr('stroke-width', @options.goalStrokeWidth)

  drawGoal2: (goal, color) ->
    y = Math.floor(@transY2(goal)) + 0.5
    if not @options.horizontal
      path = "M#{@xStart},#{y}H#{@xEnd}"
    else
      path = "M#{y},#{@xStart}V#{@xEnd}"

    @raphael.path(path)
      .attr('stroke', color)
      .attr('stroke-width', @options.goalStrokeWidth2)

  drawRegion: (region, color) ->
    if region instanceof Array
      from = Math.min(Math.max(region...), @ymax)
      to = Math.max(Math.min(region...), @ymin)
      if not @options.horizontal
        from = Math.floor(@transY(from))
        to = Math.floor(@transY(to)) - from
        @raphael.rect(@xStart, from, @xEnd-@xStart, to)
          .attr({ fill: color, stroke: false })
          .toBack()
      else
        to = Math.floor(@transY(to))
        from = Math.floor(@transY(from)) - to
        @raphael.rect(to, @xStart, from, @xEnd - @xStart)
          .attr({ fill: color, stroke: false })
          .toBack()

    else
      if not @options.horizontal
        y = Math.floor(@transY(area)) + 1
        path = "M#{@xStart},#{y}H#{@xEnd}"
        @raphael.path(path)
          .attr('stroke', color)
          .attr('stroke-width', 2)
      else
        y = Math.floor(@transY(area)) + 1
        path = "M#{y},#{@xStart}V#{@xEnd}"
        @raphael.path(path)
          .attr('stroke', color)
          .attr('stroke-width', 2)

  drawEvent: (event, color) ->
    if event instanceof Array
      [from, to] = event
      from = Math.floor(@transX(from)) + 0.5
      to = Math.floor(@transX(to)) + 0.5

      if not @options.horizontal
        @raphael.rect(from, @yEnd, to-from, @yStart-@yEnd)
          .attr({ fill: color, stroke: false })
          .toBack()
      else
        @raphael.rect(@yStart, from, @yEnd-@yStart, to-from)
          .attr({ fill: color, stroke: false })
          .toBack()

    else
      x = Math.floor(@transX(event)) + 0.5
      if not @options.horizontal
        path = "M#{x},#{@yStart}V#{@yEnd}"
      else
        path = "M#{@yStart},#{x}H#{@yEnd}"

      @raphael.path(path)
        .attr('stroke', color)
        .attr('stroke-width', @options.eventStrokeWidth)

  drawYAxisLabel: (xPos, yPos, text, yaxis) ->
    label = @raphael.text(xPos, yPos, text)
      .attr('font-size', @options.gridTextSize)
      .attr('font-family', @options.gridTextFamily)
      .attr('font-weight', @options.gridTextWeight)
      .attr('fill', @options.gridTextColor)
    if yaxis == 1
      if @options.yLabelAlign == 'right'
        label.attr('text-anchor', 'end')
      else
        label.attr('text-anchor', 'start')
    else
      if @options.yLabelAlign2 == 'left'
        label.attr('text-anchor', 'start')
      else
        label.attr('text-anchor', 'end')

  drawXAxisLabel: (xPos, yPos, text) ->
    @raphael.text(xPos, yPos, text)
      .attr('font-size', @options.gridTextSize)
      .attr('font-family', @options.gridTextFamily)
      .attr('font-weight', @options.gridTextWeight)
      .attr('fill', @options.gridTextColor)

  drawGridLine: (path) ->
    @raphael.path(path)
      .attr('stroke', @options.gridLineColor)
      .attr('stroke-width', @options.gridStrokeWidth)

  # Range selection
  #
  startRange: (x) ->
    @hover.hide()
    @selectFrom = x
    @selectionRect.attr({ x: x, width: 0 }).show()

  endRange: (x) ->
    if @selectFrom
      start = Math.min(@selectFrom, x)
      end = Math.max(@selectFrom, x)
      @options.rangeSelect.call @el,
        start: @data[@hitTest(start)].x
        end: @data[@hitTest(end)].x
      @selectFrom = null

  mousemoveHandler: (evt) =>
    offset = Morris.offset(@el)
    x = evt.pageX - offset.left
    if @selectFrom
      left = @data[@hitTest(Math.min(x, @selectFrom))]._x
      right = @data[@hitTest(Math.max(x, @selectFrom))]._x
      width = right - left
      @selectionRect.attr({ x: left, width: width })
    else
      @fire 'hovermove', x, evt.pageY - offset.top

  mouseleaveHandler: (evt) =>
    if @selectFrom
      @selectionRect.hide()
      @selectFrom = null
    @fire 'hoverout'

  touchHandler: (evt) =>
    touch = evt.originalEvent.touches[0] or evt.originalEvent.changedTouches[0]
    offset = Morris.offset(@el)
    @fire 'hovermove', touch.pageX - offset.left, touch.pageY - offset.top

  clickHandler: (evt) =>
    offset = Morris.offset(@el)
    @fire 'gridclick', evt.pageX - offset.left, evt.pageY - offset.top

  mousedownHandler: (evt) =>
    offset = Morris.offset(@el)
    @startRange evt.pageX - offset.left

  mouseupHandler: (evt) =>
    offset = Morris.offset(@el)
    @endRange evt.pageX - offset.left
    @fire 'hovermove', evt.pageX - offset.left, evt.pageY - offset.top

  resizeHandler: =>
    if @timeoutId?
      window.clearTimeout @timeoutId
    @timeoutId = window.setTimeout @debouncedResizeHandler, 100

  debouncedResizeHandler: =>
    @timeoutId = null
    {width, height} = Morris.dimensions @el
    @raphael.setSize width, height
    @options.animate = false
    @redraw()

  hasToShow: (i) =>
    @options.shown is true or @options.shown[i] is true

  isColorDark: (hex) ->
    if hex?
      hex = hex.substring(1)
      rgb = parseInt(hex, 16)
      r = (rgb >> 16) & 0xff
      g = (rgb >>  8) & 0xff
      b = (rgb >>  0) & 0xff
      luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
      if luma >= 128
        return false
      else
        return true
    else
      return false

  drawDataLabel: (xPos, yPos, text, color) ->
    label = @raphael.text(xPos, yPos, text)
                    .attr('text-anchor', 'middle')
                    .attr('font-size', @options.dataLabelsSize)
                    .attr('font-family', @options.dataLabelsFamily)
                    .attr('font-weight', @options.dataLabelsWeight)
                    .attr('fill', color)

  drawDataLabelExt: (xPos, yPos, text, anchor, color) ->
    label = @raphael.text(xPos, yPos, text)
                    .attr('text-anchor', anchor)
                    .attr('font-size', @options.dataLabelsSize)
                    .attr('font-family', @options.dataLabelsFamily)
                    .attr('font-weight', @options.dataLabelsWeight)
                    .attr('fill', color)

  setLabels: =>

    if @options.dataLabels
      for row in @data
        for ykey, index in @options.ykeys

          if @options.dataLabelsColor != 'auto'
            color = @options.dataLabelsColor
          else if @options.stacked == true && @isColorDark(@options.barColors[index%@options.barColors.length]) == true
            color = '#fff'
          else
            color = '#000'

          if @options.lineColors? and @options.lineType?
            if row.label_y[index]?
              @drawDataLabel(row._x, row.label_y[index], this.yLabelFormat_noUnit(row.y[index], 0), color)

            if row._y2?
              if row._y2[index]?
                @drawDataLabel(row._x, row._y2[index] - 10, this.yLabelFormat_noUnit(row.y[index], 1000), color)

          else
            if row.label_y[index]?
              if @options.horizontal is not true
                @drawDataLabel(row.label_x[index], row.label_y[index],@yLabelFormat_noUnit(row.y[index], index), color)
              else
                @drawDataLabelExt(row.label_x[index], row.label_y[index], @yLabelFormat_noUnit(row.y[index]), 'start', color)
            else if row._y2[index]?
              if @options.horizontal is not true
                @drawDataLabel(row._x, row._y2[index] - 10,@yLabelFormat_noUnit(row.y[index], index), color)
              else
                @drawDataLabelExt(row._y2[index], row._x - 10, @yLabelFormat_noUnit(row.y[index]), 'middle', color)

# Parse a date into a javascript timestamp
#
#
Morris.parseDate = (date) ->
  if typeof date is 'number'
    return date
  m = date.match /^(\d+) Q(\d)$/
  n = date.match /^(\d+)-(\d+)$/
  o = date.match /^(\d+)-(\d+)-(\d+)$/
  p = date.match /^(\d+) W(\d+)$/
  q = date.match /^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+)(Z|([+-])(\d\d):?(\d\d))?$/
  r = date.match /^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+(\.\d+)?)(Z|([+-])(\d\d):?(\d\d))?$/
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
    if not q[6]
      # no timezone info, use local
      new Date(
        parseInt(q[1], 10),
        parseInt(q[2], 10) - 1,
        parseInt(q[3], 10),
        parseInt(q[4], 10),
        parseInt(q[5], 10)).getTime()
    else
      # timezone info supplied, use UTC
      offsetmins = 0
      if q[6] != 'Z'
        offsetmins = parseInt(q[8], 10) * 60 + parseInt(q[9], 10)
        offsetmins = 0 - offsetmins if q[7] == '+'
      Date.UTC(
        parseInt(q[1], 10),
        parseInt(q[2], 10) - 1,
        parseInt(q[3], 10),
        parseInt(q[4], 10),
        parseInt(q[5], 10) + offsetmins)
  else if r
    secs = parseFloat(r[6])
    isecs = Math.floor(secs)
    msecs = Math.round((secs - isecs) * 1000)
    if not r[8]
      # no timezone info, use local
      new Date(
        parseInt(r[1], 10),
        parseInt(r[2], 10) - 1,
        parseInt(r[3], 10),
        parseInt(r[4], 10),
        parseInt(r[5], 10),
        isecs,
        msecs).getTime()
    else
      # timezone info supplied, use UTC
      offsetmins = 0
      if r[8] != 'Z'
        offsetmins = parseInt(r[10], 10) * 60 + parseInt(r[11], 10)
        offsetmins = 0 - offsetmins if r[9] == '+'
      Date.UTC(
        parseInt(r[1], 10),
        parseInt(r[2], 10) - 1,
        parseInt(r[3], 10),
        parseInt(r[4], 10),
        parseInt(r[5], 10) + offsetmins,
        isecs,
        msecs)
  else
    new Date(parseInt(date, 10), 0, 1).getTime()

