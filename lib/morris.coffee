Morris = window.Morris = {}

# Compute element style
compStyle = (el) ->
  if getComputedStyle # standard (includes ie9)
    getComputedStyle(el, null)
  else if el.currentStyle # IE older
    el.currentStyle
  else # inline style
    el.style

# Very simple event-emitter class.
#
# @private
class Morris.EventEmitter
  on: (name, handler) ->
    unless @handlers?
      @handlers = {}
    unless @handlers[name]?
      @handlers[name] = []
    @handlers[name].push(handler)
    @

  fire: (name, args...) ->
    if @handlers? and @handlers[name]?
      for handler in @handlers[name]
        handler(args...)

# Make long numbers prettier by inserting commas.
#
# @example
#   Morris.commas(1234567) -> '1,234,567'
Morris.commas = (num) ->
  if num?
    ret = if num < 0 then "-" else ""
    absnum = Math.abs(num)
    intnum = Math.floor(absnum).toFixed(0)
    ret += intnum.replace(/(?=(?:\d{3})+$)(?!^)/g, ',')
    strabsnum = absnum.toString()
    if strabsnum.length > intnum.length
      ret += strabsnum.slice(intnum.length)
    ret
  else
    '-'

# Zero-pad numbers to two characters wide.
#
# @example
#   Morris.pad2(1) -> '01'
Morris.pad2 = (number) -> (if number < 10 then '0' else '') + number

# Copy all properties from objects in second argument to last onto the first
# object given and return the first object. This should emulate jQuery's
# $.extend().
#
# @example
#   Morris.extend({}, { a:1 }, { b:2 }) -> '{ a:1, b:2 }'
Morris.extend = (object={}, objects...) ->
  for properties in objects when properties?
    for key, val of properties when properties.hasOwnProperty key
      object[key] = val
  object

# Emulate jQuery's $el.offset() (http://youmightnotneedjquery.com/#offset)
Morris.offset = (el) ->
  rect = el.getBoundingClientRect()
  top: rect.top + document.body.scrollTop,
  left: rect.left + document.body.scrollLeft

# Emulate jQuery's $el.css() (http://youmightnotneedjquery.com/#get_style)
Morris.css = (el, prop) -> compStyle(el)[prop]

# Emulate jQuery's $el.on()
Morris.on = (el, eventName, fn) ->
  if el.addEventListener
    el.addEventListener(eventName, fn)
  else
    el.attachEvent('on'+eventName, fn)

# Emulate jQuery's $el.off()
Morris.off = (el, eventName, fn) ->
  if el.removeEventListener
    el.removeEventListener(eventName, fn)
  else
    el.detachEvent('on'+eventName, fn)

# Emulate jQuery's $el.width() and $el.height()
Morris.dimensions = (el) ->
  style = compStyle el
  width: parseInt(style.width),
  height: parseInt(style.height)

# Emulate jQuery's $el.innerWidth() and $el.innerHeight()
Morris.innerDimensions = (el) ->
  style = compStyle el
  width: parseInt(style.width) +
    parseInt(style.paddingLeft) +
    parseInt(style.paddingRight),
  height: parseInt(style.height) +
    parseInt(style.paddingTop) +
    parseInt(style.paddingBottom)


