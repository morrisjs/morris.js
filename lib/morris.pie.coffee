class Morris.Pie
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
    sortData: false
    formatter: Morris.commas
    hideHover: false
  
  constructor: (options) ->
    if not (this instanceof Morris.Pie)
      return new Morris.Pie(options)
    
    if typeof options.element is 'string'
      @el = $ document.getElementById(options.element)
    else
      @el = $ options.element

    @options = $.extend {}, @defaults, options

    if @el == null || @el.length == 0
      throw new Error("Graph placeholder not found.")

    # bail if there's no data
    if options.data is undefined or options.data.length is 0
      return
    @setData options.data

    @el.addClass 'graph-initialised'
    
    if @options.hideHover
      @el.mouseout (evt) =>
        @hideHover()

    @redraw()

  # Set data
  setData: (data) ->
    total = data.reduce (x,y) -> value: x.value + y.value
    
    @data = $.map data, (row, index) =>
      ret = {}
      ret.label = row.label
      ret.value = row.value
      ret.segment = 100.0 * row.value / total.value
      ret
    
    if @options.sortData in [true, 'asc']
      @data = @data.sort (a,b) -> a.segment > b.segment
    else if @options.sortData is 'desc'
      @data = @data.sort (a,b) -> a.segment < b.segment

  # Clear and redraw the chart.
  #
  # If you need to re-size your charts, call this method after changing the
  # size of the container element.
  redraw: ->
    @clear()
    @calc()
    @drawPie()
  
  # Clear the container
  #
  # @private
  clear: ->
    @text = null
    @middles = []
    @segments = []
    @el.empty()
    @r = new Raphael(@el[0])
  
  # Calculations
  #
  # @private
  calc: ->
    @width = @el.width()
    @height = @el.height() - 30
    @cx = @width / 2.0
    @cy = 30 + @height / 2.0
    @radius = 0.8 * Math.min @width / 2.0, @height / 2.0
  
  # Draw circle for only one data row
  #
  # @private
  drawCircle: ->
    @r.circle(@cx, @cy, @radius)
      .attr('fill', @options.colors[0])
      .attr('stroke', 'white')
      .attr('stroke-width', 3)
      .attr('stroke-linejoin', 'round')
  
  # Draw the pie chart
  #
  # @private
  drawPie: ->
    if @data.length == 1
      segment = new Morris.PieCircle(@cx, @cy, @radius, @options.colors[0], @data[0])
      segment.render @r
      segment.on 'hover', @select
      @segments.push segment
      @select segment if not @options.hideHover
      return
      
    angle = 0
    for row, sidx in @data
      mangle = angle - 360.0 * row.segment / 200.0
      if not sidx
        angle = 90 - mangle
        mangle = angle - 360.0 * row.segment / 200.0
      [from, to] = [angle, angle - 3.6 * row.segment]
      segment = new Morris.PieSegment(@cx, @cy, @radius, from, to, @options.colors[sidx % @options.colors.length], row)
      segment.render @r
      segment.on 'hover', @select
      @segments.push segment
      angle = to
      
    if not @options.hideHover
      max_value = Math.max.apply(null, row.value for row in @data)
      for row, idx in @data
        if row.value == max_value
          @select idx
          break
  
  # Select the segment at the given index.
  select: (idx) =>
    s.deselect() for s in @segments
    if typeof idx is 'number' then segment = @segments[idx] else segment = idx
    segment.select()
    @showLabel segment.data.label, @options.formatter(segment.data.value), segment.color
  
  showLabel: (label, value, color) ->
    if @text is null
      @text = @r.text(@cx, 30, "#{label}: #{value}")
                .attr('font-size', 15)
                .attr('font-weight', 800)
    
    @text.attr('fill': color, 'text': "#{label}: #{value}")

  hideHover: ->
    s.deselect() for s in @segments
    @text.attr('text', '') if @text

class Morris.PieCircle extends Morris.EventEmitter
  constructor: (@cx, @cy, @radius, @color, @data) ->
  
  render: (r) ->
    @circle = r.circle(@cx, @cy, @radius - 5)
      .attr(fill: @color, stroke: 'white', 'stroke-width': 3, 'stroke-linejoin': 'round')
      .hover(=> @fire('hover', @))
  
  select: =>
    unless @selected
      @circle.animate(r: @radius, 150, '<>')
      @selected = true

  deselect: =>
    if @selected
      @circle.animate(r: @radius - 5, 150, '<>')
      @selected = false

class Morris.PieSegment extends Morris.EventEmitter
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
  
  select: =>
    unless @selected
      @seg.animate(path: @selectedPath, 150, '<>')
      @selected = true

  deselect: =>
    if @selected
      @seg.animate(path: @path, 150, '<>')
      @selected = false