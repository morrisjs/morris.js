Array::isUniform = (value, compare) ->
  value = value ? @[0]
  compare = compare ? (a, b) -> a == b
  return true if @.length == 0
  for el in @
    return false if not compare(el, value)
  return true

class Morris.Pie extends Morris.EventEmitter
  defaults:
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
    sort: false
    formatter: Morris.commas
    showLabel: "hover"
    includeZeros: false
  
  constructor: (options) ->
    if not (this instanceof Morris.Pie)
      return new Morris.Pie(options)
    
    @el = $ options.element
    if @el is null or @el.length == 0
      throw new Error("Container element not found.")
    
    if options.data is undefined or options.data.length is 0
      return
    
    @options = $.extend {}, @defaults, options
    @setData options.data
    
    if @options.showLabel is "hover"
      @el.mouseout (evt) => @hideLabel()
    
    @redraw()
  
  setData: (data) ->
    total = data.reduce (x,y) -> value: x.value + y.value
    total.value = 1 if total.value == 0
    
    @data = []
    for row, i in data
      @data.push
        label: row.label
        value: row.value
        segment: row.value / total.value * 100
        id: row[@options.idKey]
    
    if @data.isUniform(0)
      for row in @data
        row.segment = 100 / @data.length
    
    if @options.sortData in [true, "asc"]
      @data = @data.sort (a,b) -> a.segment > b.segment
    else if @options.sortData is "desc"
      @data = @data.sort (a,b) -> a.segment < b.segment
    
  redraw: ->
    @clear()
    @calc()
    @draw()
  
  clear: ->
    @label = ""
    @middles = []
    @segments = []
    @el.empty()
    @r = new Raphael(@el[0])
  
  calc: ->
    @width = @el.width()
    @height = @el.height()
    @cx = @width / 2.0
    @cy = @height / 2.0
    @radius = 0.8 * Math.min(@cx, @cy)
    
    unless @options.showLabel is false
      @height -= 30
      @cy += 30
  
  select: (i) ->
    segment.deselect() for segment in @segments
    segment = i
    segment = @segments[i] if typeof i is "number"
    segment.select()
    
    if @options.showLabel isnt false
      @showLabel segment
  
  showLabel: (segment) ->
    if @text is null
      @text = @r.text(@cx, 30, "").attr({"font-size": 15, "font-weight": "bold"})
    @text.attr
      fill: segment.color
      text: "#{segment.label}: #{segment.value}"
  
  hideLabel: ->
    segment.deselect() for segment in @segments
    @text.attr("text", "") if @text isnt null
  
  draw: ->
    if @data.length == 1
      @drawSingle()
    else
      @drawSegments()
  
  drawSingle: ->
    row = @data[0]
    if @options.includeZeros or row.segment > 0
      @genSingle row
  
  drawSegments: ->
    angle = 0
    for row, i in @data
      mangle = angle - 360 * row.segment / 200
      if not i
        angle = 90 - mangle
        mangle = angle - 360.0 * row.segment / 200
      [from, to] = [angle, angle - 3.6 * row.segment]
      angle = to
      segment = @genSegment row, from, to, i
      segment.render @r
      segment.on "hover", @select
      @segments.push segment
    if @options.showLabel is true
      @select @data.length - 1
  
  genSingle: (row) ->
  
  genSegment: (row, from, to, i) ->

class Morris.Pie.FullSegment extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, @color, @data) ->
    @selected = false
  
  render: (r) ->
    @seg = r.circle(@cx, @cy, @radius - 5)
            .attr(fillr: @color, stroke: "white", "stroke-width": 3, "stroke-linejoin": "round")
            .hover(=> @fire("hover", @))
  
  select: ->
    unless @selected
      @circle.animate(r: @radius, 150, "<>")
      @selected = true
  
  deselect: ->
    if @selected
      @circle.animate(r: @radius - 5, 150, "<>")
      @selected = false

class Morris.Pie.Segment extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, from, to, @color, @data) ->
    rad = Math.PI / 180
    @diff = Math.abs(to-from)
    @cos = Math.cos(-(from + (to-from) / 2) * rad)
    @sin = Math.sin(-(from + (to-from) / 2) * rad)
    @sin_from = Math.sin(-from * rad)
    @cos_from = Math.cos(-from * rad)
    @sin_to = Math.sin(-to * rad)
    @cos_to = Math.cos(-to * rad)
    @long = +(@diff > 180)
    @path = @calcSegment(@radius - 5)
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
    @seg = r.path(@path)
      .attr(fill: @color, stroke: 'white', 'stroke-width': 3, 'stroke-linejoin': 'round')
      .hover(=> @fire('hover', @))
  
  select: ->
    unless @selected
      @seg.animate(path: @selectedPath, 150, '<>')
      @selected = true

  deselect: ->
    if @selected
      @seg.animate(path: @path, 150, '<>')
      @selected = false