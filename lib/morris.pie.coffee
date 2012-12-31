Morris.isUniform = (array, value, compare) ->
  value = value ? array[0]
  compare = compare ? (a, b) -> a == b
  return true if array.length == 0
  for el in array
    return false if not compare(el, value)
  return true

class Morris.Pie extends Morris.EventEmitter
  pieDefaults:
    colors: [
      '#0B62A4'
      '#3980B5'
      '#679DC6'
      '#95BBD7'
      '#B0CCE1'
      '#095791'
      '#095085'
      '#083E67'
      '#052C48'
      '#042135'
    ]
    idKey: "label"
    stroke: "#FFFFFF"
    strokeWidth: 3
    sort: false
    formatter: Morris.commas
    showLabel: "hover"
    drawOut: 5
    minSectorAngle: 5
  
  constructor: (options) ->
    if not (this instanceof Morris.Pie)
      return new Morris.Pie(options)
    
    if typeof options.element is 'string'
      @el = $ document.getElementById(options.element)
    else
      @el = $ options.element
    
    if @el is null or @el.length == 0
      throw new Error("Container element not found.")
    
    if options.data is undefined or options.data.length is 0
      return
    
    @options = $.extend {}, @pieDefaults, options
    @setData options.data
    
    if @options.showLabel is "hover"
      @el.mouseout (evt) => @hideLabel()
    
    if @options.showLabel isnt true
      @el.mouseout (evt) => @deselect()
    
    @redraw()
  
  setData: (data) ->
    total = 0
    for row in data
      total = total + row.value
    
    total = 1 if total == 0
    
    @data = []
    for row in data
      @data.push
        label: row.label
        value: @options.formatter(row.value, row)
        sector: row.value / total * 100
        angle: row.value / total * 360
        id: row[@options.idKey]
    
    if Morris.isUniform(@data, 0, (a, v) -> a.sector == v)
      for row in @data
        row.sector = 100 / @data.length
    
    angles = (row.angle for row in @data)
    
    updateSum = 0
    for angle, i in angles when angle < @options.minSectorAngle
      angles[i] = @options.minSectorAngle
      updateSum += @options.minSectorAngle - angle

    sumAngles = 0
    for angle, i in angles when angle >= updateSum * 2
      sumAngles += angle

    for angle, i in angles when angle >= updateSum * 2
      angles[i] = angle - updateSum * angle / sumAngles

    for angle, i in angles
      @data[i].angle = angle
      @data[i].sector = angle / 3.6

    if @options.sortData in [true, "asc"]
      @data = @data.sort (a,b) -> a.sector > b.sector
    else if @options.sortData is "desc"
      @data = @data.sort (a,b) -> a.sector < b.sector
    
  redraw: ->
    @clear()
    @calc()
    @draw()
  
  clear: ->
    @label = null
    @middles = []
    @sectors = []
    @el.empty()
    @r = new Raphael(@el[0])
  
  calc: ->
    @width = @el.width()
    @height = @el.height()
    @height -= 30 if @options.showLabel isnt false
    @cx = @width / 2.0
    @cy = @height / 2.0
    @radius = 0.8 * Math.min(@cx, @cy)
    @cy += 30 if @options.showLabel isnt false

  select: (i) ->
    s.deselect() for s in @sectors
    sector = i
    sector = @sectors[i] if typeof i is "number"
    sector.select()
    
    @fire "hover", sector.data.id, sector.data
    
    if @options.showLabel isnt false
      @showLabel sector
  
  showLabel: (sector) ->
    if @label is null
      @label = @r.text(@cx, 30, "").attr({"font-size": 15, "font-weight": "bold"})
    @label.attr
      fill: sector.color
      text: "#{sector.data.label}: #{sector.data.value}"
  
  hideLabel: ->
    @deselect()
    @label.attr("text", "") if @label isnt null
  
  deselect: ->
    s.deselect() for s in @sectors
  
  draw: ->
    if @data.length == 1
      @drawSingle()
    else
      @drawSectors()
  
  drawSingle: ->
    angle = 90 + 360 * @data[0].sector / 200
    
    sector = @genSingle @data[0], angle, angle - 3.6 * @data[0].sector
    sector.render @r
    sector.on "hover", (s) => @select(s)
    sector.on "click", (id, data) => @fire "click", id, data
    @sectors.push sector
    
    if @options.showLabel is true
      @select(0)
  
  drawSectors: ->
    angle = 0
    for row, i in @data
      continue if row.sector == 0
      mangle = angle - 360 * row.sector / 200
      if not i
        angle = 90 - mangle
        mangle = angle - 360.0 * row.sector / 200
      [from, to] = [angle, angle - 3.6 * row.sector]
      angle = to
      sector = @genSector row, from, to, i
      sector.render @r
      sector.on "hover", (s) => @select(s)
      sector.on "click", (id, data) => @fire("click", id, data)
      @sectors.push sector
    if @options.showLabel is true
      @select @data.length - 1
  
  genSingle: (row) ->
    new Morris.Pie.FullSector(@cx, @cy, @radius, @getColor(0), row, @options)
  
  genSector: (row, from, to, i) ->
    new Morris.Pie.Sector(@cx, @cy, @radius, from, to, @getColor(i), row, @options)
  
  getColor: (i) ->
    if typeof @options.colors is "function"
      return @options.colors.call(@data[i], i, @options)
    else
      return @options.colors[i % @options.colors.length];

class Morris.Pie.FullSector extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, @color, @data, @options) ->
    @selected = false
  
  render: (r) ->
    @sec = r.circle(@cx, @cy, @radius - @options.drawOut)
            .attr(fillr: @color, stroke: @options.stroke, "stroke-width": @options.strokeWidth, "stroke-linejoin": "round")
            .hover(=> @fire("hover", @))
            .click(=> @fire("click", @data.id, @data))
  
  select: ->
    unless @selected
      @sec.animate(r: @radius, 150, "<>")
      @selected = true
  
  deselect: ->
    if @selected
      @sec.animate(r: @radius - @options.drawOut, 150, "<>")
      @selected = false

class Morris.Pie.Sector extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, from, to, @color, @data, @options) ->
    rad = Math.PI / 180
    @diff = Math.abs(to-from)
    @cos = Math.cos(-(from + (to-from) / 2) * rad)
    @sin = Math.sin(-(from + (to-from) / 2) * rad)
    @sin_from = Math.sin(-from * rad)
    @cos_from = Math.cos(-from * rad)
    @sin_to = Math.sin(-to * rad)
    @cos_to = Math.cos(-to * rad)
    @long = +(@diff > 180)
    @path = @calcSegment(@radius - @options.drawOut)
    @selectedPath = @calcSegment(@radius)
    @selected = false
    @mx = @cx + @radius / 2 * @cos
    @my = @cy + @radius / 2 * @sin
  
  calcArcPoints: (r) ->
    [
      @cx + r * @cos_from
      @cy + r * @sin_from
      @cx + r * @cos_to
      @cy + r * @sin_to
    ]
  
  calcSegment: (r) ->
    [x1, y1, x2, y2] = @calcArcPoints(r)
    "M#{@cx},#{@cy}L#{x1},#{y1}A#{r},#{r},0,#{@long},1,#{x2},#{y2}Z"
  
  render: (r) ->
    @sec = r.path(@path)
      .attr(fill: @color, stroke: @options.stroke, 'stroke-width': @options.strokeWidth, 'stroke-linejoin': 'round')
      .hover(=> @fire('hover', @))
      .click(=> @fire("click", @data.id, @data))
  
  select: ->
    unless @selected
      @sec.animate(path: @selectedPath, 150, '<>')
      @selected = true

  deselect: ->
    if @selected
      @sec.animate(path: @path, 150, '<>')
      @selected = false