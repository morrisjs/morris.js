class Morris.Donut extends Morris.Pie
  donutDefaults:
    width: "50%"
  
  constructor: (options) ->
    return new Morris.Donut(options) unless (@ instanceof Morris.Donut)
    super($.extend {}, @donutDefaults, options)
  
  genSector: (row, from, to, i) ->
    new Morris.Donut.Sector(@cx, @cy, @radius, from, to, @getColor(i), row, @options)
  
  genSingle: (row, from, to) ->
    new Morris.Donut.FullSector(@cx, @cy, @radius, @getColor(0), row, @options)

class Morris.Donut.FullSegment extends Morris.EventEmitter
  constructor: (@cx, @cy, @r, @color, @data, @options) ->
    rad = Math.PI / 180
    
    width = @options.width
    width = @r * parseFloat(width) / 100 if width.match(/[0-9]+(\.[0-9]+)?\%/)
    
    @rin = @r - width
    @drawOut = @options.drawOut
    @drawOutInner = 0.5 * @options.drawOut * @rin / @r
    @selected = false
    
    @swidth = width + @drawOut - @drawOutInner - @options.strokeWidth * 2
    @width = width - @options.strokeWidth * 2
    
    @r = @r - width/2 - @options.strokeWidth
    @sr = @r + (@drawOut + @drawOutInner)/2
    
    @path = ["M", @cx, @cy - @r, "A", @r, @r, 0, 1, 1, @cx - 0.01, @cy - @r]
    @selectedPath = ["M", @cx, @cy - @sr, "A", @sr, @sr, 0, 1, 1, @cx - 0.01, @cy - @sr]
  
  render: (r) ->
    @sec = r.path(@path)
      .attr('stroke': @color, 'stroke-width': @width)
      .hover(=> @fire('hover', @))
      .click(=> @fire("click", @))
  
  select: ->
    unless @selected
      attrs = path: @selectedPath, 'stroke-width': @swidth
      @sec.animate(attrs, 150, '<>')
      @selected = true

  deselect: ->
    if @selected
      attrs = path: @path, 'stroke-width': @width
      @sec.animate(attrs, 150, '<>')
      @selected = false

class Morris.Donut.Sector extends Morris.EventEmitter
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
    @sec = r.path(@path)
      .attr(fill: @color, stroke: @options.stroke, 'stroke-width': @options.strokeWidth, 'stroke-linejoin': 'round')
      .hover(=> @fire('hover', @))
      .click(=> @fire("click", @))
  
  select: ->
    unless @selected
      @sec.animate(path: @selectedPath, 150, '<>')
      @selected = true

  deselect: ->
    if @selected
      @sec.animate(path: @path, 150, '<>')
      @selected = false
