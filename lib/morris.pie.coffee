Array::isUniform = (value, compare) ->
  value = value ? @[0]
  compare = compare ? (a, b) -> a == b
  return true if @.length == 0
  for el in @
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
    includeZeros: false
  
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
    total = data.reduce (x,y) -> value: x.value + y.value
    total.value = 1 if total.value == 0
    
    @data = []
    for row, i in data
      @data.push
        label: row.label
        value: @options.formatter.call(null, row.value, row)
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
    @label = null
    @middles = []
    @segments = []
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
    s.deselect() for s in @segments
    segment = i
    segment = @segments[i] if typeof i is "number"
    segment.select()
    
    @fire "hover", segment.data.id, segment.data
    
    if @options.showLabel isnt false
      @showLabel segment
  
  showLabel: (segment) ->
    if @label is null
      @label = @r.text(@cx, 30, "").attr({"font-size": 15, "font-weight": "bold"})
    @label.attr
      fill: segment.color
      text: "#{segment.data.label}: #{segment.data.value}"
  
  hideLabel: ->
    @deselect()
    @label.attr("text", "") if @label isnt null
  
  deselect: ->
    s.deselect() for s in @segments
  
  draw: ->
    if @data.length == 1
      @drawSingle()
    else
      @drawSegments()
  
  drawSingle: ->
    segment = @genSingle @data[0]
    segment.render @r
    segment.on "hover", (s) => @select(s)
    segment.on "click", (id, data) => @fire "click", id, data
    @segments.push segment
    
    if @options.showLabel is true
      @select(0)
  
  drawSegments: ->
    angle = 0
    for row, i in @data
      continue if row.segment == 0
      mangle = angle - 360 * row.segment / 200
      if not i
        angle = 90 - mangle
        mangle = angle - 360.0 * row.segment / 200
      [from, to] = [angle, angle - 3.6 * row.segment]
      angle = to
      segment = @genSegment row, from, to, i
      segment.render @r
      segment.on "hover", (s) => @select(s)
      segment.on "click", (id, data) => @fire("click", id, data)
      @segments.push segment
    if @options.showLabel is true
      @select @data.length - 1
  
  genSingle: (row) ->
    new Morris.Pie.FullSegment(@cx, @cy, @radius, @getColor(0), row, @options)
  
  genSegment: (row, from, to, i) ->
    new Morris.Pie.Segment(@cx, @cy, @radius, from, to, @getColor(i), row, @options)
  
  getColor: (i) ->
    if typeof @options.colors is "function"
      return @options.colors.call(@data[i], i, @options)
    else
      return @options.colors[i % @options.colors.length];

class Morris.Pie.FullSegment extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, @color, @data, @options) ->
    @selected = false
  
  render: (r) ->
    @seg = r.circle(@cx, @cy, @radius - @options.drawOut)
            .attr(fillr: @color, stroke: @options.stroke, "stroke-width": @options.strokeWidth, "stroke-linejoin": "round")
            .hover(=> @fire("hover", @))
            .click(=> @fire("click", @data.id, @data))
  
  select: ->
    unless @selected
      @seg.animate(r: @radius, 150, "<>")
      @selected = true
  
  deselect: ->
    if @selected
      @seg.animate(r: @radius - @options.drawOut, 150, "<>")
      @selected = false

class Morris.Pie.Segment extends Morris.EventEmitter
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
    @seg = r.path(@path)
      .attr(fill: @color, stroke: @options.stroke, 'stroke-width': @options.strokeWidth, 'stroke-linejoin': 'round')
      .hover(=> @fire('hover', @))
      .click(=> @fire("click", @data.id, @data))
  
  select: ->
    unless @selected
      @seg.animate(path: @selectedPath, 150, '<>')
      @selected = true

  deselect: ->
    if @selected
      @seg.animate(path: @path, 150, '<>')
      @selected = false