class Morris.Bar extends Morris.Grid
  # Initialise the graph.
  #
  constructor: (options) ->
    return new Morris.Bar(options) unless (@ instanceof Morris.Bar)
    super($.extend {}, options, parseTime: false)

  # setup event handlers
  #
  init: ->
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

  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcBars()
    @calcHoverMargins()

  # calculate series data bars coordinates and sizes
  #
  # @private
  calcBars: ->
    for row, idx in @data
      row._x = @left + @width * (idx + 0.5) / @data.length
      row._y = for y in row.y
        if y is null then null else @transY(y)

  # calculate hover margins
  #
  # @private
  calcHoverMargins: ->
    @hoverMargins = for i in [1...@data.length]
      @left + i * @width / @data.length

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
    for i in [0...@data.length]
      row = @data[@data.length - 1 - i]
      label = @r.text(row._x, ypos, row.label)
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
            .attr('fill', @options.barColors[sidx % @options.barColors.length])
            .attr('stroke-width', 0)
        else
          null

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
      yLabel = @r.text(0, @options.hoverFontSize * 1.5 * (i + 1.5) - @hoverHeight / 2, '')
        .attr('font-size', @options.hoverFontSize)
      @yLabels.push(yLabel)
      @hoverSet.push(yLabel)

  # @private
  updateHover: (index) =>
    @hoverSet.show()
    row = @data[index]
    @xLabel.attr('text', row.label)
    for y, i in row.y
      @yLabels[i].attr('fill', @options.barColors[i % @options.barColors.length])
      @yLabels[i].attr('text', "#{@options.labels[i]}: #{@yLabelFormat(y)}")
    # recalculate hover box width
    maxLabelWidth = Math.max.apply null, $.map @yLabels, (l) ->
      l.getBBox().width
    maxLabelWidth = Math.max maxLabelWidth, @xLabel.getBBox().width
    @hover.attr 'width', maxLabelWidth + @options.hoverPaddingX * 2
    @hover.attr 'x', -@options.hoverPaddingX - maxLabelWidth / 2
    # move to y pos
    yloc = (@bottom + @top) / 2
    xloc = Math.min @right - maxLabelWidth / 2 - @options.hoverPaddingX, @data[index]._x
    xloc = Math.max @left + maxLabelWidth / 2 + @options.hoverPaddingX, xloc
    @hoverSet.attr 'transform', "t#{xloc},#{yloc}"

  # @private
  hideHover: ->
    @hoverSet.hide()

  # @private
  hilight: (index) =>
    if index isnt null and @prevHilight isnt index
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
