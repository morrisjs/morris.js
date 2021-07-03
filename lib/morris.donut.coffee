# Donut charts.
#
# @example
#   Morris.Donut({
#     el: $('#donut-container'),
#     data: [
#       { label: 'yin',  value: 50 },
#       { label: 'yang', value: 50 }
#     ]
#   });
class Morris.Donut extends Morris.EventEmitter
  defaults:
    colors: [
      '#2f7df6'
      '#53a351'
      '#f6c244'
      '#cb444a'
      '#4aa0b5'
      '#222529'
      '#44a1f8'
      '#81d453'
      '#f0bb40'
      '#eb3f25'
      '#b45184'
      '#5f5f5f'
    ],
    backgroundColor: '#FFFFFF',
    labelColor: '#000000',
    padding: 0
    formatter: Morris.commas
    resize: true,
    dataLabels: false,
    dataLabelsPosition: 'inside',
    dataLabelsFamily: 'sans-serif',
    dataLabelsSize: 12,
    dataLabelsWeight: 'normal',
    dataLabelsColor: 'auto',
    noDataLabel: 'No data for this chart',
    noDataLabelSize: 21,
    noDataLabelWeight: 'bold',
    donutType: 'donut',
    animate: true,
    showPercentage: false,
    postUnits: '',
    preUnits: ''

  # Create and render a donut chart.
  #
  constructor: (options) ->
    return new Morris.Donut(options) unless (@ instanceof Morris.Donut)
    @options = Morris.extend {}, @defaults, options

    if typeof options.element is 'string'
      @el = document.getElementById(options.element)
    else
      @el = options.element[0] or options.element

    if @el == null
      throw new Error("Graph placeholder not found.")

    @raphael = new Raphael(@el)

    # bail if there's no data
    if options.data is undefined or options.data.length is 0
      {width, height} = Morris.dimensions @el
      cx = width / 2
      cy = height / 2
      @raphael.text(cx, cy, @options.noDataLabel)
              .attr('text-anchor', 'middle')
              .attr('font-size', @options.noDataLabelSize)
              .attr('font-family', @options.dataLabelsFamily)
              .attr('font-weight', @options.noDataLabelWeight)
              .attr('fill', @options.dataLabelsColor)
      return

    if @options.resize
      Morris.on window, 'resize', @resizeHandler

    @setData options.data

  # Destroy
  #
  destroy: () ->
    if @options.resize
      window.clearTimeout @timeoutId
      Morris.off window, 'resize', @resizeHandler

  # Clear and redraw the chart.
  redraw: ->
    @raphael.clear()

    {width, height} = Morris.dimensions @el
    cx = width / 2
    cy = height / 2
    w = (Math.min(cx, cy) - 10) / 3 - @options.padding

    total = 0
    total += value for value in @values
    @options.total = total

    min = 5 / (2 * w)
    C = 1.9999 * Math.PI - min * @data.length

    last = 0
    idx = 0
    @segments = []
    if total == 0
      total = 1

    for value, i in @values
      next = last + min + C * (value / total)
      seg = new Morris.DonutSegment(
        cx, cy, w*2, w, last, next,
        @data[i].color || @options.colors[idx % @options.colors.length],
        @options.backgroundColor, idx, @raphael, @options)
      seg.render()
      @segments.push seg
      seg.on 'hover', @select
      seg.on 'click', @click
      seg.on 'mouseout', @deselect
      if parseFloat(seg.raphael.height) > parseFloat(height)
        dist = height  * 2 - @options.padding * 7
      else
        dist = seg.raphael.height - @options.padding * 7

      if @options.data[i].ratio is undefined
        @options.data[i].ratio = 1

      dist = dist * @options.data[i].ratio

      if @options.dataLabels && @values.length >= 1
        p_sin_p0 = Math.sin((last + next)/2);
        p_cos_p0 = Math.cos((last + next)/2);
        if @options.dataLabelsPosition == 'inside'
          if @options.donutType == 'pie'
            label_x = parseFloat(cx) + parseFloat((dist) * 0.30 * p_sin_p0);
            label_y = parseFloat(cy) + parseFloat((dist) * 0.30 * p_cos_p0);
          else
            label_x = parseFloat(cx) + parseFloat((dist) * 0.39 * p_sin_p0);
            label_y = parseFloat(cy) + parseFloat((dist) * 0.39 * p_cos_p0);
        else
          label_x = parseFloat(cx) + parseFloat((dist - 9) * 0.5 * p_sin_p0);
          label_y = parseFloat(cy) + parseFloat((dist - 9) * 0.5 * p_cos_p0);

        if @options.dataLabelsColor != 'auto'
          color = @options.dataLabelsColor
        else if @options.dataLabelsPosition == 'inside' && @isColorDark(@options.colors[i]) == true
          color = '#fff'
        else
          color = '#000'

        if @options.showPercentage
          finalValue = Math.round(parseFloat(value) / parseFloat(total) * 100) + '%'
          @drawDataLabelExt(label_x,label_y, finalValue, color)
        else
          @drawDataLabelExt(label_x,label_y, @options.preUnits+value+@options.postUnits, color)

      last = next
      idx += 1

    @text1 = @drawEmptyDonutLabel(cx, cy - 10, @options.labelColor, 15, 800)
    @text2 = @drawEmptyDonutLabel(cx, cy + 10, @options.labelColor, 14)

    max_value = Math.max @values...
    idx = 0

    if @options.donutType == 'donut'
      for value in @values
        if value == max_value
          @select idx
          break
        idx += 1

  setData: (data) ->
    @data = data
    @values = (parseFloat(row.value) for row in @data)
    @redraw()

  drawDataLabel: (xPos, yPos, text, color) ->
    label = @raphael.text(xPos, yPos, text)
                    .attr('text-anchor', 'middle')
                    .attr('font-size', @options.dataLabelsSize)
                    .attr('font-family', @options.dataLabelsFamily)
                    .attr('font-weight', @options.dataLabelsWeight)
                    .attr('fill', @options.dataLabelsColor)

  drawDataLabelExt: (xPos, yPos, text, color) ->
    if @values.length >= 1
      labelAnchor = 'middle'
    else if @options.dataLabelsPosition == 'inside'
      labelAnchor = 'middle'
    else if xPos > this.raphael.width / 2
      labelAnchor = 'start'
    else if xPos > this.raphael.width * 0.55 && xPos < this.raphael.width * 0.45
      labelAnchor = 'middle'
    else
      labelAnchor = 'end'
    label = @raphael.text(xPos, yPos, text, color)
                    .attr('text-anchor', labelAnchor)
                    .attr('font-size', @options.dataLabelsSize)
                    .attr('font-family', @options.dataLabelsFamily)
                    .attr('font-weight', @options.dataLabelsWeight)
                    .attr('fill', color)

  # @private
  click: (idx) =>
    @fire 'click', idx, @data[idx]

  # Select the segment at the given index.
  select: (idx) =>
    s.deselect() for s in @segments
    segment = @segments[idx]
    segment.select()
    row = @data[idx]
    if @options.donutType == 'donut'

      if @options.showPercentage && !@options.dataLabels
        finalValue = Math.round(parseFloat(row.value) / parseFloat(@options.total) * 100) + '%'
        @setLabels(row.label, finalValue)
      else
        @setLabels(row.label, @options.formatter(row.value, row))

  deselect: (idx) =>
    s.deselect() for s in @segments

  isColorDark: (hex) ->
    if hex?
      hex = hex.substring(1)
      rgb = parseInt(hex, 16)
      r = (rgb >> 16) & 0xff
      g = (rgb >>  8) & 0xff
      b = (rgb >>  0) & 0xff
      luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
      if luma >= 128
        return false
      else
        return true
    else
      return false

  # @private
  setLabels: (label1, label2) ->
    {width, height} = Morris.dimensions(@el)
    inner = (Math.min(width / 2, height / 2) - 10) * 2 / 3
    maxWidth = 1.8 * inner
    maxHeightTop = inner / 2
    maxHeightBottom = inner / 3
    @text1.attr(text: label1, transform: '')
    text1bbox = @text1.getBBox()
    text1scale = Math.min(maxWidth / text1bbox.width, maxHeightTop / text1bbox.height)
    @text1.attr(transform: "S#{text1scale},#{text1scale},#{text1bbox.x + text1bbox.width / 2},#{text1bbox.y + text1bbox.height}")
    @text2.attr(text: label2, transform: '')
    text2bbox = @text2.getBBox()
    text2scale = Math.min(maxWidth / text2bbox.width, maxHeightBottom / text2bbox.height)
    @text2.attr(transform: "S#{text2scale},#{text2scale},#{text2bbox.x + text2bbox.width / 2},#{text2bbox.y}")

  drawEmptyDonutLabel: (xPos, yPos, color, fontSize, fontWeight) ->
    text = @raphael.text(xPos, yPos, '')
      .attr('font-size', fontSize)
      .attr('fill', color)
    text.attr('font-weight', fontWeight) if fontWeight?
    return text

  resizeHandler: =>
    if @timeoutId?
      window.clearTimeout @timeoutId
    @timeoutId = window.setTimeout @debouncedResizeHandler, 100

  debouncedResizeHandler: =>
    @timeoutId = null
    {width, height} =  Morris.dimensions @el
    @raphael.setSize width, height
    @options.animate = false
    @redraw()

# A segment within a donut chart.
#
# @private
class Morris.DonutSegment extends Morris.EventEmitter
  constructor: (@cx, @cy, @inner, @outer, p0, p1, @color, @backgroundColor, @index, @raphael, @options) ->
    @sin_p0 = Math.sin(p0)
    @cos_p0 = Math.cos(p0)
    @sin_p1 = Math.sin(p1)
    @cos_p1 = Math.cos(p1)
    @is_long = if (p1 - p0) > Math.PI then 1 else 0

    if @options.data[@index].ratio is undefined
        @options.data[@index].ratio = 1
    inner = @inner  * @options.data[@index].ratio
    @path = @calcSegment(inner + 3, inner + @outer - 5)
    @selectedPath = @calcSegment(inner + 3, inner + @outer)
    @hilight = @calcArc(inner)

  calcArcPoints: (r) ->
    return [
      @cx + r * @sin_p0,
      @cy + r * @cos_p0,
      @cx + r * @sin_p1,
      @cy + r * @cos_p1]

  calcSegment: (r1, r2) ->
    [ix0, iy0, ix1, iy1] = @calcArcPoints(r1)
    [ox0, oy0, ox1, oy1] = @calcArcPoints(r2)
    if @options.donutType == 'pie'
      return (
        "M#{ox0},#{oy0}" +
        "A#{r2},#{r2},0,#{@is_long},0,#{ox1},#{oy1}" +
        "L#{@cx},#{@cy}" +
        "Z")
    else
      return (
        "M#{ix0},#{iy0}" +
        "A#{r1},#{r1},0,#{@is_long},0,#{ix1},#{iy1}" +
        "L#{ox1},#{oy1}" +
        "A#{r2},#{r2},0,#{@is_long},1,#{ox0},#{oy0}" +
        "Z")

  calcArc: (r) ->
    [ix0, iy0, ix1, iy1] = @calcArcPoints(r)
    return (
      "M#{ix0},#{iy0}" +
      "A#{r},#{r},0,#{@is_long},0,#{ix1},#{iy1}")

  render: ->
    if !/NaN/.test @hilight
      @arc = @drawDonutArc(@hilight, @color)

    if !/NaN/.test @path
      @seg = @drawDonutSegment(
        @path,
        @color,
        @backgroundColor,
        => @fire('hover', @index),
        => @fire('click', @index),
        => @fire('mouseout', @index)
      )

  drawDonutArc: (path, color) ->
    if @options.animate
      rPath = @raphael.path("M"+this.cx+","+this.cy+"Z")
        .attr(stroke: color, 'stroke-width': 2, opacity: 0)
      do (rPath, path) =>
        rPath.animate {path}, 500, '<>'
    else
      @raphael.path(path)
            .attr(stroke: color, 'stroke-width': 2, opacity: 0)

  drawDonutSegment: (path, fillColor, strokeColor, hoverFunction, clickFunction, leaveFunction) ->
    if @options.animate && @options.donutType == 'pie'
      straightPath = path;
      straightPath = path.replace('A', ',');
      straightPath = straightPath.replace('M', '');
      straightPath = straightPath.replace('C', ',');
      straightPath = straightPath.replace('Z', '');
      straightDots = straightPath.split(',');

      if @options.donutType == 'pie'
        straightPath = 'M'+straightDots[0]+','+straightDots[1]+','+straightDots[straightDots.length-2]+','+straightDots[straightDots.length-1]+','+straightDots[straightDots.length-2]+','+straightDots[straightDots.length-1]+'Z'
      else
        straightPath = 'M'+straightDots[0]+','+straightDots[1]+','+straightDots[straightDots.length-2]+','+straightDots[straightDots.length-1]+'Z'

      rPath = @raphael.path(straightPath)
        .attr(fill: fillColor, stroke: strokeColor, 'stroke-width': 3)
        .hover(hoverFunction)
        .click(clickFunction)
        .mouseout(leaveFunction)

      do (rPath, path) =>
        rPath.animate {path}, 500, '<>'
    else
      if @options.donutType == 'pie'
        @raphael.path(path)
          .attr(fill: fillColor, stroke: strokeColor, 'stroke-width': 3)
          .hover(hoverFunction)
          .click(clickFunction)
          .mouseout(leaveFunction)
      else
        @raphael.path(path)
          .attr(fill: fillColor, stroke: strokeColor, 'stroke-width': 3)
          .hover(hoverFunction)
          .click(clickFunction)

  select: =>
    unless @selected
      if @seg?
        @seg.animate(path: @selectedPath, 150, '<>')
        @arc.animate(opacity: 1, 150, '<>')
        @selected = true

  deselect: =>
    if @selected
      @seg.animate(path: @path, 150, '<>')
      @arc.animate(opacity: 0, 150, '<>')
      @selected = false
