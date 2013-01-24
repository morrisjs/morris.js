class Morris.Area extends Morris.Line
  # Initialise
  #
  constructor: (options) ->
    return new Morris.Area(options) unless (@ instanceof Morris.Area)
    @cumulative = true
    super(options)

  # calculate series data point coordinates
  #
  # @private
  calcPoints: ->
    for row in @data
      row._x = @transX(row.x)
      total = 0
      row._y = for y in row.y
        total += (y || 0)
        @transY(total)
      row._ymax = row._y[row._y.length - 1]

  # draw the data series
  #
  # @private
  drawSeries: ->
    for i in [@options.ykeys.length-1..0]
      path = @paths[i]
      if path isnt null
        path = path + "L#{@transX(@xmax)},#{@bottom}L#{@transX(@xmin)},#{@bottom}Z"
        @drawFilledPath(path, @fillForSeries(i))
    super()

  fillForSeries: (i) ->
    color = Raphael.rgb2hsl @colorFor(@data[i], i, 'line')
    Raphael.hsl(
      color.h,
      Math.min(255, color.s * 0.75),
      Math.min(255, color.l * 1.25))

  drawFilledPath: (path, fill) ->
    @raphael.path(path)
      .attr('fill', fill)
      .attr('stroke-width', 0)
