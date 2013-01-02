class Morris.Hover
  # Displays contextual information in a floating HTML div.

  @defaults:
    cssPrefix: 'morris'
    position: 'auto'
    class: ['-hover', '-default-style']

  constructor: (options = {}) ->
    @options = $.extend {}, Morris.Hover.defaults, options
    @el = $ "<div class='#{@buildClassAttr(@options.class)}'></div>"
    @el.hide()
    @options.parent.append(@el)

  buildClassAttr: (c) ->
    if typeof c is 'string'
      c = [c]
    classes = []
    for class_ in c
      classes.push(if class_.indexOf('-') is 0 then @options.cssPrefix + class_ else class_)
    classes.join ' '


  update: (html, x, y) ->
    @html(html)
    @show()
    @moveTo(x, y)

  html: (content) ->
    @el.html(content)

  moveTo: (x, y) ->
    p = @options.cssPrefix
    @el.removeClass "#{p}-hover-below #{p}-hover-above #{p}-hover-left #{p}-hover-right"

    parentWidth  = @options.parent.innerWidth()
    parentHeight = @options.parent.innerHeight()
    hoverWidth   = @el.outerWidth()
    hoverHeight  = @el.outerHeight()

    if @options.position in ['absolute', 'absolute above']
      left = x - hoverWidth / 2
      top = y - hoverHeight - 10
      @el.addClass "#{p}-hover-above"
    else if @options.position is 'absolute below'
      left = x - hoverWidth / 2
      top = y + 10
      @el.addClass "#{p}-hover-below"
    else if @options.position is 'absolute left'
      left = x - hoverWidth - 10
      top = y - hoverHeight / 2
      @el.addClass "#{p}-hover-left"
    else if @options.position is 'absolute right'
      left = x + 10
      top = y - hoverHeight / 2
      @el.addClass "#{p}-hover-right"
    else
      left = Math.min(Math.max(0, x - hoverWidth / 2), parentWidth - hoverWidth)
      if y?
        top = y - hoverHeight - 10
        if top < 0
          top = y + 10
          if top + hoverHeight > parentHeight
            top = parentHeight / 2 - hoverHeight / 2
          else
            @el.addClass "#{p}-hover-below"
        else
          @el.addClass "#{p}-hover-above"
      else
        top = parentHeight / 2 - hoverHeight / 2
    @el.css(left: left + "px", top: top + "px")

  show: ->
    @el.show()

  hide: ->
    @el.hide()
