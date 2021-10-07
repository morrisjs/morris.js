class Morris.Area extends Morris.Line
  # Initialise
  #
  areaDefaults =
    fillOpacity: 'auto'
    behaveLikeLine: false
    belowArea: true
    areaColors: []

  constructor: (options) ->
    return new Morris.Area(options) unless (@ instanceof Morris.Area)
    areaOptions = Morris.extend {}, areaDefaults, options

    @cumulative = not areaOptions.behaveLikeLine

    if areaOptions.fillOpacity is 'auto'
      areaOptions.fillOpacity = if areaOptions.behaveLikeLine then .8 else 1

    super(areaOptions)

  # calculate series data point coordinates
  #
  # @private
  calcPoints: ->
    for row in @data
      row._x = @transX(row.x)
      total = 0
      row._y = for y in row.y
        if @options.behaveLikeLine
          if y? then @transY(y) else y
        else
          if y?
            total += (y || 0)
            @transY(total)
      row._ymax = Math.max [].concat(y for y, i in row._y when y?)...

    for row, idx in @data
      @data[idx].label_x = []
      @data[idx].label_y = []
      for index in [@options.ykeys.length-1..0]
        if row._y[index]?
          @data[idx].label_x[index] = row._x
          @data[idx].label_y[index] = row._y[index] - 10

        if row._y2?
          if row._y2[index]?
            @data[idx].label_x[index] = row._x
            @data[idx].label_y[index] = row._y2[index] - 10

  # draw the data series
  #
  # @private
  drawSeries: ->
    @seriesPoints = []
    if @options.behaveLikeLine
      range = [0..@options.ykeys.length-1]
    else
      range = [@options.ykeys.length-1..0]

    for i in range
      @_drawFillFor i

    for i in range
      @_drawLineFor i
      @_drawPointFor i

  _drawFillFor: (index) ->
    path = @paths[index]
    if path isnt null
      if @options.belowArea is true
          path = path + "L#{@transX(@xmax)},#{@bottom}L#{@transX(@xmin)},#{@bottom}Z"
          @drawFilledPath path, @fillForSeries(index), index

      else
        coords = ({x: r._x, y: r._y[0]} for r in @data by - 1 when r._y[0] isnt undefined)
        pathBelow = Morris.Line.createPath coords, 'smooth', @bottom
        path = path + "L" + pathBelow.slice(1)
        @drawFilledPath path, @fillForSeries(index), index

  fillForSeries: (i) ->
    if @options.areaColors.length == 0 then @options.areaColors = @options.lineColors
    color = Raphael.rgb2hsl @options.areaColors[i % @options.areaColors.length]
    Raphael.hsl(
      color.h,
      if @options.behaveLikeLine then color.s * 0.9 else color.s * 0.75,
      Math.min(0.98, if @options.behaveLikeLine then color.l * 1.2 else color.l * 1.25))

  drawFilledPath: (path, fill, areaIndex) ->
    if @options.animate
      coords = ({x: r._x, y: @transY(0)} for r in @data when r._y[areaIndex] isnt undefined)
      straightPath = Morris.Line.createPath coords, 'smooth', @bottom
      if @options.belowArea is true
        straightPath = straightPath + "L#{@transX(@xmax)},#{@bottom}L#{@transX(@xmin)},#{@bottom}Z"
      else
        coords = ({x: r._x, y: @transY(0)} for r in @data by - 1 when r._y[areaIndex] isnt undefined)
        pathBelow = Morris.Line.createPath coords, 'smooth', @bottom
        straightPath = straightPath + "L" + pathBelow.slice(1)

      straightPath += 'Z';
      rPath = @raphael.path(straightPath)
                      .attr('fill', fill)
                      .attr('fill-opacity', this.options.fillOpacity)
                      .attr('stroke', 'none')
      do (rPath, path) =>
        rPath.animate {path}, 500, '<>'
    else
      @raphael.path(path)
        .attr('fill', fill)
        .attr('fill-opacity', @options.fillOpacity)
        .attr('stroke', 'none')
