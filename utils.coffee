
# shorthands
window.str = (x) -> JSON.stringify x
# window.log = (x) -> console.log x
window.warn = (x) -> console.warn x
window.assert = (condition, message) ->
    if not condition
        throw message or "Assertion failed"

# are any true?
window.any = (list) ->
    for x in list
        if x
            return true
    return false

# are all true?
window.all = (list) ->
    for x in list
        if not x
            return false
    return false

window.extendArray = (array, toAppend) ->
    Array.prototype.push.apply(array, toAppend)

window.flatten = (lists) ->
    flat = []
    for list in lists
        extendArray(flat, list)
    return flat

# math function
window.sqrt = Math.sqrt
window.lerp = (a, b, t) ->
    (1.0 - t) * a   +   t * b

window.length = (dx, dy) ->
    sqrt(dx*dx + dy*dy)


# padds a string to be of a certian width
window.pad = (n, width, padChar) ->
    padChar = padChar || '0'
    n = n + ''
    if n.length >= width
        return n
    else
        return new Array(width - n.length + 1).join(padChar) + n


# same as console.log but does it at most 100 times
counter100 = 0
window.print100 = (string) ->
    counter100 += 1
    if counter100 <= 100
        console.log string

# shows one of the last two arguments mutually exclusively
window.showIfTrue = (condition, showTrue, showFalse) ->
    if condition
        $(showTrue ).removeClass('hidden')
        $(showFalse).addClass('hidden')
    else
        $(showTrue ).addClass('hidden')
        $(showFalse).removeClass('hidden')
