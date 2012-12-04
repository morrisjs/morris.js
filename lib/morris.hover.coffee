class Morris.Hover
  # Displays contextual information in a floating HTML div.
  #
  constructor: (options = {}) ->
    @options = $.extend {}, Morris.Hover.defaults, options
    @el = $ "<div class='#{@options.class}'></div>"
    @el.hide()

  @defaults:
    class: 'morris-popup'
    allowOverflow: false

  show: (x, y, data) ->
    if typeof @options.content is 'function'
      @el.html @options.content(data)
    else
      @el.html @options.content
    @el.show()

  hide: ->
    @el.hide()

