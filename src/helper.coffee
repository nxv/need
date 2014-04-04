path      = require 'path'

###*
 * Same to _.pairs
 * @param  {Object} o The Object to zip
 * @return {Array}    Zipped array
###
pairs = (o) ->
  [i, o[i]] for i in Object.keys o

copy = (o) ->
  r={};r[k]=v for k,v of o;r

extend = (t, f) ->
  t[k]=v for k,v of f;t

indexOfHead = (s, a) ->
  for k, i in a
    [h] = [].concat k
    return i if h is s
  -1

typefor = (o) ->
  Object.prototype.toString.call(o)
  .match(/\[object (.*)\]/)[1]
  .toLowerCase()

mergeAlias = (o, alias) ->
  r = copy o
  for v in alias
    for a in v
      if r[a]?
        r[v[0]] = r[a]
        delete r[b] for b in v[1..]
        break
  r

extendAlias = (o, alias) ->
  r = copy o
  for [h, b...] in alias
    for k in b
      if (v = o[h])?
        r[k] = v
      else delete r[k]
  r

neatenAlias = (o, alias) ->
  extendAlias mergeAlias(
    o, alias), alias

getCaller = (offset = 0) ->
  traceFn = Error.prepareStackTrace
  Error.prepareStackTrace = (e, s) -> s
  stack = (new Error()).stack
  Error.prepareStackTrace = traceFn
  f = stack[2 - offset].getFileName()
  file: path.basename f
  path: path.dirname f
  fullpath: f

module.exports = {
  typefor
  pairs
  copy
  indexOfHead
  extend
  mergeAlias
  extendAlias
  neatenAlias
  getCaller
}