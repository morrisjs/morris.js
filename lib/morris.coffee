Morris = window.Morris = {}

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
Morris.extend = (object, objects...) ->
  for properties in objects
    for key, val of properties
      object[key] = val
  object

# Emulate jQuery's $el.offset() (http://youmightnotneedjquery.com/#offset)
Morris.offset = (el) ->
  rect = el.getBoundingClientRect()
  top: rect.top + document.body.scrollTop,
  left: rect.left + document.body.scrollLeft

# Emulate jQuery's $el.css() (http://youmightnotneedjquery.com/#get_style)
Morris.css = (el, ruleName) -> getComputedStyle(el)[ruleName]
