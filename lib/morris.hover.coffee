class Morris.Hover
  # Displays contextual information in a floating HTML div.

  @defaults:
    class: 'morris-hover morris-default-style'

  constructor: (options = {}) ->
    @options = Morris.extend {}, Morris.Hover.defaults, options
    @el = document.createElement 'div'
    @el.className = @options.class
    @el.style.display = 'none'
    (@options.parent = @options.parent[0] or @options.parent).appendChild @el

  update: (html, x, y, centre_y) ->
    if not html
      @hide()
    else
      @html(html)
      @show()
      @moveTo(x, y, centre_y)

  html: (content) ->
    @el.innerHTML = content

  moveTo: (x, y, centre_y) ->
    {width:parentWidth, height:parentHeight} =
      Morris.innerDimensions @options.parent
    hoverWidth  = @el.offsetWidth
    hoverHeight = @el.offsetHeight
    left = Math.min(Math.max(0, x - hoverWidth / 2), parentWidth - hoverWidth)
    if y?
      if centre_y is true
        top = y - hoverHeight / 2
        if top < 0
          top = 0
      else
        top = y - hoverHeight - 10
        if top < 0
          top = y + 10
          if top + hoverHeight > parentHeight
            top = parentHeight / 2 - hoverHeight / 2
    else
      top = parentHeight / 2 - hoverHeight / 2

    @el.style.left = parseInt(left) + "px"
    @el.style.top = parseInt(top) + "px"

  show: ->
    @el.style.display = ''

  hide: ->
    @el.style.display = 'none'