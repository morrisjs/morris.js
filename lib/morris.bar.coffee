class Morris.Bar extends Morris.Grid
  # Initialise the graph.
  #
  constructor: (options) ->
    return new Morris.Bar(options) unless (@ instanceof Morris.Bar)
    super(options)
  
  init: ->
    # Some instance variables for later
    @barFace = Raphael.animation opacity: @options.barHoverOpacity, 25, 'linear'
    @barDeface = Raphael.animation opacity: 1.0, 25, 'linear'
    # data hilight events
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
  
  # Default configuration
  #
  defaults:
    barSizeRatio: 0.5
    barGap: 3
    barStrokeWidths: [0]
    barStrokeColors: ['#ffffff']
    barFillColors: [
      '#0b62a4'
      '#7a92a3'
      '#4da74d'
      '#afd8f8'
      '#edc240'
      '#cb4b4b'
      '#9440ed'
    ]
    barHoverOpacity: 0.95
    hoverPaddingX: 10
    hoverPaddingY: 5
    hoverMargin: 10
    hoverFillColor: '#fff'
    hoverBorderColor: '#ccc'
    hoverBorderWidth: 2
    hoverOpacity: 0.95
    hoverLabelColor: '#444'
    hoverFontSize: 12
    hideHover: false
    xLabels: 'auto'
    xLabelFormat: null
  
  # Override padding
  #
  # @private
  overridePadding: ->
    maxYLabelWidth = Math.max(
      @measureText(@yAxisFormat(@ymin), @options.gridTextSize).width,
      @measureText(@yAxisFormat(@ymax), @options.gridTextSize).width)
    @left = maxYLabelWidth + @paddingLeft
    @right = @elementWidth - @paddingRight
    @width = @right - @left
    
    xgap = @width / @data.length
    @barsoffset = @options.barSizeRatio * xgap / 2.0;
    @barwidth = (@options.barSizeRatio * xgap - ( @options.ykeys.length - 1 ) * @options.barGap ) / @options.ykeys.length
    @halfBarsWidth = Math.round( @options.ykeys.length / 2 ) * ( @barwidth + @options.barGap )
    
    @paddingLeft += @halfBarsWidth
    @paddingRight += @halfBarsWidth
  
  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcBars()
    @generateBars()
    @calcHoverMargins()
  
  # calculate series data bars coordinates and sizes
  #
  # @private
  calcBars: ->
    for row in @data
      row._x = @transX(row.x)
      row._y = for y in row.y
        if y is null
          null
        else
          @transY(y)
  
  # calculate hover margins
  #
  # @private
  calcHoverMargins: ->
    @hoverMargins = $.map @data.slice(1), (r, i) => (r._x + @data[i]._x) / 2
  
  # generate bars for series
  #
  # @private
  generateBars: ->
    @bars = for i in [0..@options.ykeys.length]
      coords = ({x: r._x - @barsoffset + i * (@options.barGap + @barwidth) , y: r._y[i], v: r.y[i] } for r in @data when r._y[i] isnt null)
      if coords.length > 1
        @createBars i, coords, @barwidth
      else
        null
  
  # Draws the bar chart.
  #
  draw: ->
    @drawXAxis()
    @drawSeries()
    @drawHover()
    @hilight(if @options.hideHover then null else @data.length - 1)
  
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
      if (prevLabelMargin is null or prevLabelMargin >= labelBox.x + labelBox.width) and
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
    @seriesBars = ([] for i in [0...@options.ykeys.length])
    for i in [@options.ykeys.length-1..0]
      bars = @bars[i]
      if bars.length > 0
        for bar in bars
          if bar isnt null
            rect = @r.rect(bar.x, bar.y, bar.width, bar.height)
                     .attr('fill', bar.fill)
                     .attr('stroke', @strokeForSeries(i))
                     .attr('stroke-width', @strokeWidthForSeries(i))
          else
            rect = null
          @seriesBars[i].push(rect)
  
  # create bars for a data series
  #
  # @private
  createBars: (index, coords, barwidth) ->
    bars = []
    for coord in coords
      bars.push(
        x: coord.x
        y: coord.y
        width: barwidth
        height: @bottom - coord.y
        fill: @colorForSeriesAndValue(index, coord.v)
      )
    
    return bars
  
  # draw the hover tooltip
  #
  # @private
  drawHover: ->
    # hover labels
    @hoverHeight = @options.hoverFontSize * 1.5 * (@options.ykeys.length + 1)
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
    for i in [0...@options.ykeys.length]
      idx = if @cumulative then (@options.ykeys.length - i - 1) else i
      yLabel = @r.text(0, @options.hoverFontSize * 1.5 * (idx + 1.5) - @hoverHeight / 2, '')
        .attr('font-size', @options.hoverFontSize)
      @yLabels.push(yLabel)
      @hoverSet.push(yLabel)

  # @private
  updateHover: (index) =>
    @hoverSet.show()
    row = @data[index]
    @xLabel.attr('text', row.label)
    for y, i in row.y
      @yLabels[i].attr('fill', @hoverColorForSeriesAndValue(i, y))
      @yLabels[i].attr('text', "#{@options.labels[i]}: #{@yLabelFormat(y)}")
    # recalculate hover box width
    maxLabelWidth = Math.max.apply null, $.map @yLabels, (l) ->
      l.getBBox().width
    maxLabelWidth = Math.max maxLabelWidth, @xLabel.getBBox().width
    @hover.attr 'width', maxLabelWidth + @options.hoverPaddingX * 2
    @hover.attr 'x', -@options.hoverPaddingX - maxLabelWidth / 2
    # move to y pos
    yloc = Math.min.apply null, (y for y in row._y when y isnt null).concat(@bottom)
    if yloc > @hoverHeight + @options.hoverPaddingY * 2 + @options.hoverMargin + @top
      yloc = yloc - @hoverHeight / 2 - @options.hoverPaddingY - @options.hoverMargin
    else
      yloc = yloc + @hoverHeight / 2 + @options.hoverPaddingY + @options.hoverMargin
    yloc = Math.max @top + @hoverHeight / 2 + @options.hoverPaddingY, yloc
    yloc = Math.min @bottom - @hoverHeight / 2 - @options.hoverPaddingY, yloc
    xloc = Math.min @right - maxLabelWidth / 2 - @options.hoverPaddingX, @data[index]._x
    xloc = Math.max @left + maxLabelWidth / 2 + @options.hoverPaddingX, xloc
    @hoverSet.attr 'transform', "t#{xloc},#{yloc}"
    
  # @private
  hideHover: ->
    @hoverSet.hide()
    
  # @private
  hilight: (index) =>
    if @prevHilight isnt null and @prevHilight isnt index
      for i in [0..@seriesBars.length-1]
        if @seriesBars[i][@prevHilight]
          @seriesBars[i][@prevHilight].animate @barDeface
    if index isnt null and @prevHilight isnt index
      for i in [0..@seriesBars.length-1]
        if @seriesBars[i][index]
          @seriesBars[i][index].animate @barFace
      @updateHover index
    @prevHilight = index
    if index is null
      @hideHover()
  
  # @private
  updateHilight: (x) =>
    x -= @el.offset().left
    for hoverIndex in [0...@hoverMargins.length]
      break if @hoverMargins[hoverIndex] > x
    @hilight hoverIndex
  
  # @private
  strokeWidthForSeries: (index) ->
    @options.barStrokeWidths[index % @options.barStrokeWidths.length]

  # @private
  strokeForSeries: (index) ->
    @options.barStrokeColors[index % @options.barStrokeColors.length]
  
  # @private
  hoverColorForSeriesAndValue: (index, value) =>
    colorOrGradient = @colorForSeriesAndValue index, value
    if typeof colorOrGradient is 'string'
      return colorOrGradient.split('-').pop()
    
    return colorOrGradient
  
  # @private
  colorForSeriesAndValue: (index, value) =>
    color = @options.barFillColors[index % @options.barFillColors.length]
    if color.indexOf(' ') is -1
      return color
    
    color = color.split(/\s/)
    
    colorAt = (top, bottom, relPos) ->
      chan = (a, b) -> a + Math.round((b-a)*relPos)
      newColor =
        r: chan(top.r, bottom.r)
        g: chan(top.g, bottom.g)
        b: chan(top.b, bottom.b)
      return Raphael.color("rgb(#{newColor.r},#{newColor.g},#{newColor.b})")
    
    position = 1.0 - (value - @ymin) / (@ymax - @ymin)
    top = Raphael.color(color[0])
    bottom = Raphael.color(color[1])
    
    if color.length is 3
      bottom = Raphael.color(color[2])
      middle = Raphael.color(color[1])
      if position > 0.5
        start = colorAt(middle, bottom, 2 * (position - 0.5))
        return "90-#{bottom.hex}-#{start.hex}"
      else
        start = colorAt(top, middle, position * 2)
        middlepos = 100 - Math.round(100 * (0.5 - position) / (1.0 - position))
        return "90-#{bottom.hex}-#{middle.hex}:#{middlepos}-#{start.hex}"
    
    start = colorAt(top, bottom, position)
    return "90-#{bottom.hex}-#{start.hex}"