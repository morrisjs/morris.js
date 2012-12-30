class Morris.SVG

  constructor: (element, options) ->
    @raphael = new Raphael(element)
    @options = options

  clear: ->
    @raphael.clear()

  drawGoal: (path) ->
    @raphael.path(path)
      .attr('stroke', @options.goalLineColors[i % @options.goalLineColors.length])
      .attr('stroke-width', @options.goalStrokeWidth)

  drawEvent: (path) ->
    @raphael.path(path)
      .attr('stroke', @options.eventLineColors[i % @options.eventLineColors.length])
      .attr('stroke-width', @options.eventStrokeWidth)

  drawYAxisLabel: (xPos, yPos, text) ->
    @raphael.text(xPos, yPos, text)
      .attr('font-size', @options.gridTextSize)
      .attr('fill', @options.gridTextColor)
      .attr('text-anchor', 'end')

  drawXAxisLabel: (xPos, yPos, text) ->
    label = @raphael.text(xPos, yPos, text)
      .attr('font-size', @options.gridTextSize)
      .attr('fill', @options.gridTextColor)

  drawGridLine: (path) ->
    @raphael.path(path)
      .attr('stroke', @options.gridLineColor)
      .attr('stroke-width', @options.gridStrokeWidth)

  measureText: (text, fontSize = 12) ->
    tt = @raphael.text(100, 100, text).attr('font-size', fontSize)
    ret = tt.getBBox()
    tt.remove()
    ret

  drawEmptyDonutLabel: (xPos, yPos, fontSize, fontWeight) ->
    text = @raphael.text(xPos, yPos, '').attr('font-size', fontSize)
    text.attr('font-weight', fontWeight) if fontWeight?
    return text

  drawDonutArc: (path, color) ->
    @raphael.path(path).attr(stroke: color, 'stroke-width': 2, opacity: 0)

  drawDonutSegment: (path, color, hoverFunction) ->
    @raphael.path(path)
      .attr(fill: color, stroke: 'white', 'stroke-width': 3)
      .hover(hoverFunction)

  drawFilledPath: (path, fill) ->
    @raphael.path(path)
      .attr('fill', fill)
      .attr('stroke-width', 0)

  drawLinePath: (path, lineColor) ->
    @raphael.path(path)
      .attr('stroke', lineColor)
      .attr('stroke-width', @options.lineWidth)

  drawLinePoint: (xPos, yPos, size, pointColor, lineIndex) ->
    circle = @raphael.circle(xPos, yPos, size)
      .attr('fill', pointColor)
      .attr('stroke-width', @strokeWidthForSeries(lineIndex))
      .attr('stroke', @strokeForSeries(lineIndex))

  drawBar: (xPos, yPos, width, height, barColor) ->
    @raphael.rect(xPos, yPos, width, height)
      .attr('fill', barColor)
      .attr('stroke-width', 0)

  # @private
  strokeWidthForSeries: (index) ->
    @options.pointWidths[index % @options.pointWidths.length]

  # @private
  strokeForSeries: (index) ->
    @options.pointStrokeColors[index % @options.pointStrokeColors.length]
