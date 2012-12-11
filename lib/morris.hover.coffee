class Morris.Hover
  # Displays contextual information in a floating HTML div.

  @defaults:
    class: 'morris-popup'

  constructor: (options = {}) ->
    @options = $.extend {}, Morris.Hover.defaults, options
    @el = $ "<div class='#{@options.class}'></div>"
    @el.hide()
    @options.parent.append(@el)

  update: (x, y, data) ->
    @render(data)
    @show()
    @moveTo(x, y)

  render: (data) ->
    if typeof @options.content is 'function'
      @el.html @options.content(data)
    else
      @el.html @options.content

  moveTo: (x, y) ->
    parentWidth  = @options.parent.innerWidth()
    parentHeight = @options.parent.innerHeight()
    hoverWidth   = @el.outerWidth()
    hoverHeight  = @el.outerHeight()
    left = Math.min(Math.max(0, x - hoverWidth / 2), parentWidth - hoverWidth)
    if y?
      top = y - hoverHeight - 10
      if top < 0
        top = y + 10
        if top + hoverHeight > parentHeight
          top = parentHeight / 2 - hoverHeight / 2
    else
      top = parentHeight / 2 - hoverHeight / 2
    @el.css(left: left + "px", top: top + "px")

  show: ->
    @el.show()

  hide: ->
    @el.hide()
