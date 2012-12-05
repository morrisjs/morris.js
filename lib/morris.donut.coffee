class Morris.Donut extends Morris.Pie
  donutDefaults:
    width: "50%"
  
  constructor: (options) ->
    return new Morris.Donut(options) unless (@ instanceof Morris.Donut)
    super($.extend {}, @donutDefaults, options)
  
  genSingle: (row) ->
    new Morris.Donut.FullSegment(@cx, @cy, @radius, @getColor(0), row, @options)
  
  genSegment: (row, from, to, i) ->
    new Morris.Donut.Segment(@cx, @cy, @radius, from, to, @getColor(i), row, @options)

class Morris.Donut.Segment extends Morris.EventEmitter
  constructor: (@cx, @cy, @r, to, from, @color, @data, @options) ->
    rad = Math.PI / 180
    @long = +(to - from > 180)
    @sin_from = Math.sin(-from * rad)
    @cos_from = Math.cos(-from * rad)
    @sin_to = Math.sin(-to * rad)
    @cos_to = Math.cos(-to * rad)
    
    width = @options.width
    width = @r * parseFloat(width) / 100 if width.match(/[0-9]+(\.[0-9]+)?\%/)
    
    @rin = @r - width
    @drawOut = @options.drawOut
    @drawOutInner = 0.5 * @options.drawOut * @rin / @r
    @selected = false
    
    @path = @calcSegment(@r - @drawOut, @rin - @drawOutInner)
    @selectedPath = @calcSegment(@r, @rin)
  
  calcArcPoints: (r) ->
    [
      @cx + r * @cos_from
      @cy + r * @sin_from
      @cx + r * @cos_to
      @cy + r * @sin_to
    ]
  
  calcSegment: (r, rin) ->
    [x1, y1, x2, y2] = @calcArcPoints(r)
    [xx1, yy1, xx2, yy2] = @calcArcPoints(rin)
    
    path = [
      "M", xx1, yy1,
      "L", x1, y1,
      "A", r, r, 0, @long, 0, x2, y2,
      "L", xx2, yy2,
      "A", rin, rin, 0, @long, 1, xx1, yy1, "z"
    ]
  
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


class Morris.Donut.FullSegment extends Morris.Donut.Segment
  constructor: (@cx, @cy, @r, @color, @data, @options) ->
    return new Morris.Donut.FullSegment(@cx, @cy, @r, @color, @data, @options) unless (@ instanceof Morris.Donut.FullSegment)
    super(@cx, @cy, @r, 0, Math.PI * 2, @color, @data, @options)