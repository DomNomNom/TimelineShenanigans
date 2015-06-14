
console.log 'I EXIST'

# shorthands
window.str = (x) -> JSON.stringify x
window.log = (x) -> console.log x
window.warn = (x) -> console.warn x
window.assert = (condition, message) ->
    if not condition
        throw message or "Assertion failed"

window.extendArray = (array, toAppend) ->
    Array.prototype.push.apply(array, toAppend)

window.flatten = (lists) ->
    flat = []
    for list in lists
        extendArray(flat, list)
    return flat
