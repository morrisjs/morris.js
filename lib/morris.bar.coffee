class Morris.Bar extends Morris.Grid
  @include Morris.Hover
  
  # override hoverCalculatePosition
  hoverGetPosition: (index) ->
    [x, y] = Morris.Hover.hoverGetPosition.call(this, index)
    
    [x, (@top + @bottom)/2 - @hoverHeight/2]
  
  constructor: (options) ->
    return new Morris.Bar(options) unless (@ instanceof Morris.Bar)
    super($.extend {}, options, parseTime: false)

  init: ->
    @hoverConfigure @options.hoverOptions
  
  postInit: ->
    @hoverInit()
    
  defaults:
    barSizeRatio: 0.75
    barGap: 3
    barColors: [
      '#0b62a4'
      '#7a92a3'
      '#4da74d'
      '#afd8f8'
      '#edc240'
      '#cb4b4b'
      '#9440ed'
    ]

  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcBars()
    @hoverCalculateMargins()

  # calculate series data bars coordinates and sizes
  #
  # @private
  calcBars: ->
    for row, idx in @data
      row._x = @left + @width * (idx + 0.5) / @data.length
      row._y = for y in row.y
        if y? then @transY(y) else null

  # Draws the bar chart.
  #
  draw: ->
    @drawXAxis()
    @drawSeries()
    
  # draw the x-axis labels
  #
  # @private
  drawXAxis: ->
    # draw x axis labels
    ypos = @bottom + @options.gridTextSize * 1.25
    xLabelMargin = 50 # make this an option?
    prevLabelMargin = null
    for i in [0...@data.length]
      row = @data[@data.length - 1 - i]
      label = @r.text(row._x, ypos, row.label)
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

  # draw the data series
  #
  # @private
  drawSeries: ->
    groupWidth = @width / @options.data.length
    numBars = @options.ykeys.length
    barWidth = (groupWidth * @options.barSizeRatio - @options.barGap * (numBars - 1)) / numBars
    leftPadding = groupWidth * (1 - @options.barSizeRatio) / 2
    zeroPos = if @ymin <= 0 and @ymax >= 0 then @transY(0) else null
    @bars = for row, idx in @data
      for ypos, sidx in row._y
        if ypos != null
          if zeroPos
            top = Math.min(ypos, zeroPos)
            bottom = Math.max(ypos, zeroPos)
          else
            top = ypos
            bottom = @bottom
          left = @left + idx * groupWidth + leftPadding + sidx * (barWidth + @options.barGap)
          @r.rect(left, top, barWidth, bottom - top)
            .attr('fill', @colorFor(row, sidx, 'bar'))
            .attr('stroke-width', 0)
        else
          null

  # @private
  #
  # @param row  [Object] row data
  # @param sidx [Number] series index
  # @param type [String] "bar" or "hover"
  colorFor: (row, sidx, type) ->
    if typeof @options.barColors is 'function'
      r = { x: row.x, y: row.y[sidx], label: row.label }
      s = { index: sidx, key: @options.ykeys[sidx], label: @options.labels[sidx] }
      @options.barColors.call(@, r, s, type)
    else
      @options.barColors[sidx % @options.barColors.length]
