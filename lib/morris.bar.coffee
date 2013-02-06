class Morris.Bar extends Morris.Grid
  constructor: (options) ->
    return new Morris.Bar(options) unless (@ instanceof Morris.Bar)
    super($.extend {}, options, parseTime: false)

  init: ->
    @cumulative = @options.stacked

    if @options.hideHover isnt 'always'
      @hover = new Morris.Hover(parent: @el)
      @on('hovermove', @onHoverMove)
      @on('hoverout', @onHoverOut)

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
    xLabelMargin: 50

  # Do any size-related calculations
  #
  # @private
  calc: ->
    @calcBars()
    if @options.hideHover is false
      @hover.update(@hoverContentForRow(@data.length - 1)...)

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
    @drawXAxis() if @options.axes
    @drawSeries()

  # draw the x-axis labels
  #
  # @private
  drawXAxis: ->
    # draw x axis labels
    ypos = @bottom + @options.gridTextSize * 1.25
    prevLabelMargin = null
    for i in [0...@data.length]
      row = @data[@data.length - 1 - i]
      label = @drawXAxisLabel(row._x, ypos, row.label)
      labelBox = label.getBBox()
      # ensure a minimum of `xLabelMargin` pixels between labels, and ensure
      # labels don't overflow the container
      if (not prevLabelMargin? or prevLabelMargin >= labelBox.x + labelBox.width) and
          labelBox.x >= 0 and (labelBox.x + labelBox.width) < @el.width()
        prevLabelMargin = labelBox.x - @options.xLabelMargin
      else
        label.remove()

  # draw the data series
  #
  # @private
  drawSeries: ->
    groupWidth = @width / @options.data.length
    numBars = if @options.stacked? then 1 else @options.ykeys.length
    barWidth = (groupWidth * @options.barSizeRatio - @options.barGap * (numBars - 1)) / numBars
    leftPadding = groupWidth * (1 - @options.barSizeRatio) / 2
    zeroPos = if @ymin <= 0 and @ymax >= 0 then @transY(0) else null
    @bars = for row, idx in @data
      lastTop = 0
      for ypos, sidx in row._y
        if ypos != null
          if zeroPos
            top = Math.min(ypos, zeroPos)
            bottom = Math.max(ypos, zeroPos)
          else
            top = ypos
            bottom = @bottom

          left = @left + idx * groupWidth + leftPadding
          left += sidx * (barWidth + @options.barGap) unless @options.stacked
          size = bottom - top

          top -= lastTop if @options.stacked
          @drawBar(left, top, barWidth, size, @colorFor(row, sidx, 'bar'))

          lastTop += size
        else
          null

  # @private
  #
  # @param row  [Object] row data
  # @param sidx [Number] series index
  # @param type [String] "bar", "hover" or "label"
  colorFor: (row, sidx, type) ->
    if typeof @options.barColors is 'function'
      r = { x: row.x, y: row.y[sidx], label: row.label }
      s = { index: sidx, key: @options.ykeys[sidx], label: @options.labels[sidx] }
      @options.barColors.call(@, r, s, type)
    else
      @options.barColors[sidx % @options.barColors.length]

  # hit test - returns the index of the row beneath the given coordinate
  #
  hitTest: (x, y) ->
    return null if @data.length == 0
    x = Math.max(Math.min(x, @right), @left)
    Math.min(@data.length - 1,
      Math.floor((x - @left) / (@width / @data.length)))

  # hover movement event handler
  #
  # @private
  onHoverMove: (x, y) =>
    index = @hitTest(x, y)
    @hover.update(@hoverContentForRow(index)...)

  # hover out event handler
  #
  # @private
  onHoverOut: =>
    if @options.hideHover is 'auto'
      @hover.hide()

  # hover content for a point
  #
  # @private
  hoverContentForRow: (index) ->
    if typeof @options.hoverCallback is 'function'
      content = @options.hoverCallback(index, @options)
    else
      row = @data[index]
      content = "<div class='morris-hover-row-label'>#{row.label}</div>"
      for y, j in row.y
        content += """
          <div class='morris-hover-point' style='color: #{@colorFor(row, j, 'label')}'>
            #{@options.labels[j]}:
            #{@yLabelFormat(y)}
          </div>
        """
    x = @left + (index + 0.5) * @width / @data.length
    [content, x]

  drawXAxisLabel: (xPos, yPos, text) ->
    label = @raphael.text(xPos, yPos, text)
      .attr('font-size', @options.gridTextSize)
      .attr('fill', @options.gridTextColor)

  drawBar: (xPos, yPos, width, height, barColor) ->
    @raphael.rect(xPos, yPos, width, height)
      .attr('fill', barColor)
      .attr('stroke-width', 0)
