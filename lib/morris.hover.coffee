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
    @el.css(
      left: (x - @el.outerWidth() / 2) + "px"
      top:  (y - @el.outerHeight() - 10) + "px")

  show: ->
    @el.show()

  hide: ->
    @el.hide()
