Morris.Hover =
  hoverConfigure: (options) ->
    @hoverOptions = $.extend {}, @hoverDefaults, options ? {}
  
  hoverInit: ->
    if @hoverOptions.enableHover
      @hover = @hoverBuild()
      @hoverBindEvents()
      @hoverShow(if @hoverOptions.hideHover then null else @data.length - 1)
  
  hoverDefaults:
    enableHover: true
    popupClass: "morris-popup"
    hideHover: false
    allowOverflow: false
    pointMargin: 10
    hoverFill: (index, row) -> @hoverFill(index, row)
  
  hoverBindEvents: ->
    @el.mousemove (evt) =>
      @hoverUpdate evt.pageX
    if @hoverOptions.hideHover
      @el.mouseout (evt) =>
        @hoverShow null
    touchHandler = (evt) =>
      touch = evt.originalEvent.touches[0] or evt.originalEvent.changedTouches[0]
      @hoverUpdate touch.pageX
      return touch
    @el.bind 'touchstart', touchHandler
    @el.bind 'touchmove', touchHandler
    @el.bind 'touchend', touchHandler
    
    @hover.mousemove (evt) -> evt.stopPropagation()
    @hover.mouseout (evt) -> evt.stopPropagation()
    @hover.bind 'touchstart', (evt) -> evt.stopPropagation()
    @hover.bind 'touchmove', (evt) -> evt.stopPropagation()
    @hover.bind 'touchend', (evt) -> evt.stopPropagation()
  
  hoverCalculateMargins: ->
    @hoverMargins = for i in [1...@data.length]
      @left + i * @width / @data.length
  
  hoverBuild: ->
    hover = $ "<div/>"
    hover.addClass "#{@hoverOptions.popupClass} js-morris-popup"
    hover.appendTo @el
    hover.hide()
    hover
  
  hoverUpdate: (x) ->
    x -= @el.offset().left
    for hoverIndex in [0...@hoverMargins.length]
      break if @hoverMargins[hoverIndex] > x
    @hoverShow hoverIndex
  
  hoverShow: (index) ->
    if index isnt null
      @hover.html("")
      @hoverOptions.hoverFill.call(@, index, @data[index])
      @hoverPosition(index)
      @fire "hover.show", index
      @hover.show()
    if not index?
      @hoverHide()
  
  hoverHide: ->
    @hover.hide()
  
  colorFor: (row, i, type) -> "inherit"
  yLabelFormat: (label) -> Morris.commas(label)
  
  hoverPosition: (index) ->
    [x, y] = @hoverGetPosition index
    
    @hover.css
      top: "#{@el.offset().top + y}px"
      left: "#{@el.offset().left + x}px"
  
  hoverGetPosition: (index) ->
    row = @data[index]
    
    @hoverWidth = @hover.outerWidth(true)
    @hoverHeight = @hover.outerHeight(true)
    
    miny = y = Math.min.apply(null, (y for y in row._y when y isnt null).concat(@bottom))
    
    x = row._x - @hoverWidth/2
    y = miny
    y = y - @hoverHeight - @hoverOptions.pointMargin
    
    unless @hoverOptions.allowOverflow
      if x < @left
        x = row._x + @hoverOptions.pointMargin
      else if x > @right - @hoverWidth
        x = row._x - @hoverWidth - @hoverOptions.pointMargin
      
      y = Math.max y, @top
      y = Math.min y, (@bottom - @hoverHeight - @hoverOptions.pointMargin)
      
      if y - miny < @hoverWidth + @hoverOptions.pointMargin
        y = miny + @hoverOptions.pointMargin
    
    [x, y]
  
  hoverFill: (index, row) ->
    xLabel = $ "<h4/>"
    xLabel.text row.label
    xLabel.appendTo @hover
    for y, i in row.y
      yLabel = $ "<p/>"
      yLabel.css "color", @colorFor(row, i, "hover")
      yLabel.text "#{@options.labels[i]}: #{@yLabelFormat(y)}"
      yLabel.appendTo @hover