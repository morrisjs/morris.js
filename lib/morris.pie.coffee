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

    enhanceMax: false


  constructor: (options)->

    return new Morris.Pie(options) if not (@ instanceof Morris.Pie)
    
    if typeof options.element is 'string'
      @el = $ document.getElementById(options.element)
    else
      @el = $ options.element

    throw new Error("Graph placeholder not found.") if @el == null || @el.length == 0

    @options = $.extend {}, @defaults, options

    # data
    return false if options.data is undefined or options.data.length is 0
    @data = options.data

    @el.addClass 'graph-initialised'

    @paper = new Raphael(@el[0])
    @segments = []
    
    @draw()

  draw: ->

    @paper.clear()

    total = 0
    total += x.value for x in @data
    max = Math.max.apply(null, x.value for x in @data)

    currentAngle = 0

    cx = @el.width() / 2
    cy = @el.height() / 2
    r = (Math.min(cx, cy) - 10) / 3

    for labelAndValue, index in @data

      value = labelAndValue.value
      label = labelAndValue.label

      step  = 360 * value / total
      color = @options.colors[index % @options.colors.length]

      pieSegment = new Morris.PieSegment(@paper, cx, cy, r, currentAngle, step, labelAndValue, color)
      pieSegment.on "hover", @select
      pieSegment.render()

      pieSegment.select() if labelAndValue.value == max && @options.enhanceMax

      @segments.push pieSegment

      currentAngle += step

  select: (segmentToSelect)=>
    segment.deselect() for segment in @segments
    segmentToSelect.select()

class Morris.PieSegment extends Morris.EventEmitter

  constructor: (@paper, @cx, @cy, @r, @currentAngle, @step, @labelAndValue, @color)->

    @rad = Math.PI / 180

    @distanceFromEdge = 30

    @labelAngle = @currentAngle + (@step / 2)
    @endAngle = @currentAngle + @step

    @x1 = @cx + @r * Math.cos(-@currentAngle * @rad)
    @x2 = @cx + @r * Math.cos(-@endAngle   * @rad)
    @y1 = @cy + @r * Math.sin(-@currentAngle * @rad)
    @y2 = @cy + @r * Math.sin(-@endAngle   * @rad)

  render: ()->
    @segment = @paper.path(["M", @cx, @cy, "L", @x1, @y1, "A", @r, @r, 0, +(@endAngle - @currentAngle > 180), 0, @x2, @y2, "z"]).attr({ fill:  @color, stroke: "#FFFFFF", "stroke-width": 2} ).hover(=> @fire('hover', @))
    @label = @paper.text(@cx + (@r + @distanceFromEdge ) * Math.cos(-@labelAngle * @rad), @cy + (@r + @distanceFromEdge ) * Math.sin(-@labelAngle * @rad), @labelAndValue.label).attr({fill: "#000000", "font-weight": "bold", stroke: "none", opacity: 1, "font-size": 12})
    @value = @paper.text(@cx + (@r + @distanceFromEdge ) * Math.cos(-@labelAngle * @rad), @cy + (@r + @distanceFromEdge ) * Math.sin(-@labelAngle * @rad) + 14, @labelAndValue.value).attr({fill: @color, stroke: "none", opacity: 1, "font-size": 12})

  select: =>
    unless @selected
      @segment.stop().animate({transform: "s1.1 1.1 " + @cx + " " + @cy}, 150, "<>")
      @selected = true

  deselect: =>
    if @selected
      @segment.stop().animate({transform: ""}, 150, "<>")
      @selected = false