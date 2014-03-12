Q         = require 'q'
fs        = require 'fs'
glob      = require 'glob'
path      = require 'path'
{inspect} = require 'util'

exists = fs.existsSync

glob = Q.denodeify glob

isFile = (p) ->
  exists(p) and fs.statSync(p).isFile()

isDir = (p) ->
  exists(p) and fs.statSync(p).isDirectory()

hasExt = (p, exts) ->
  exts = [].concat exts
  for ext in exts
    return true if p[-ext.length..] == ext

typefor = (o) ->
  Object.prototype.toString.call(o)
  .match(/\[object (.*)\]/)[1]
  .toLowerCase()

deepMap = (obj, iterator, routePrefix = []) ->
  switch typefor obj
    when 'object' then keys = Object.keys obj
    when 'array' then keys = [0...obj.length]
    else obj = [obj]; keys = [0]; single = yes
  results = {}
  promises = keys.map (key) ->
    deferred = Q.defer()
    resolved = (newItem, newKey, stepIn) ->
      if typefor newKey == 'boolean'
        [newKey, stepIn] = [stepIn, newKey]
      newKey = newKey || key
      add = (newItem) ->
        deferred.resolve results[newKey] = newItem
      unless stepIn
        return add newItem
      _route = [].concat newKey, route[1..]
      deepMap newItem, iterator, _route
        .then add
    item = obj[key]
    route = [].concat key, routePrefix
    Q iterator item, route, obj
      .spread resolved
    deferred.promise
  Q promises
    .all().then ->
      if single
        return v for k, v of results
      else results

getCaller = (offset = 0) ->
  traceFn = Error.prepareStackTrace
  Error.prepareStackTrace = (e, s) -> s
  stack = (new Error()).stack
  Error.prepareStackTrace = traceFn
  f = stack[2 - offset].getFileName()
  file: path.basename f
  path: path.dirname f
  fullpath: f

getPaths = (start) ->
  modules = 'node_modules'
  prefix = '/'
  if /^([A-Za-z]:)/.test start
    prefix = ''
  else if /^\\\\/.test start
    prefix = '\\\\'
  parts = start.split path.sep
  for part, i in parts
    continue if part is modules
    path.join prefix, parts[..i]..., modules

need = (patterns, opt = {}) ->
  opt = Object.create opt
  opt.caller = getCaller()
  opt.path = opt.caller.path
  opt.nodePaths = getPaths opt.path
  opt.glob =
    cwd: opt.path
    mark: on
    silent: on
  opt.patterns = patterns
  resolvePatterns opt
  .then loadPaths

resolvePatterns = (opt) ->
  deepMap opt.patterns, (item, route, parent) ->
    switch typefor item
    when 'function'
      [item(), true]
    when 'string'
      [glob item, opt.glob]
    else
      [item, true]
  .then (paths) ->
    opt.paths = paths
    opt

loadPaths = (opt) ->
  deepMap opt.paths, (item, route, parent) ->
    unless typefor item is 'string'
      return [item, true]
    if item.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
      loadAsFile item, opt
    else
      loadAsModule item, opt

loadAsFile = (item, opt) ->


loadAsync = (patterns, opt, callback) ->
  deepMapAsync patterns, patternIterator, callback

patternIterator = (item, route, callback) ->
  if typefor(item) is 'function'
    deepMapAsync item()
    , deepMapAsync.wrap(patternIterator, route)
    , callback
  else if typefor(item) is 'sString'
    if item.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
      # In relative file system
      traceInFilesAsync item, opt, callback
    else
      # In module paths
      traceInModulesAsync item, opt, callback
    callback null, "done with #{inspect route}: #{item}."
  else callback()

traceInFilesAsync = (pattern, opt, callback) ->
  glob pattern, opt.glob, (err, files) ->
    callback err, files && files.map (f) ->
      path.resolve opt.path, f

traceInModulesAsync = (pattern, opt, callback) ->
  globOpt = Object.create opt.glob
  paths = opt.paths || getPaths opt.path
  try
    async.eachSeries paths.reverse(), (p, callback) ->
      globOpt.cwd = p
      glob pattern, globOpt, (err, files) ->
        throw err if err
        files = files.map (f) -> path.resolve p, f
        callback files.length && files
    , (files) ->
      unless files
        return callback new Error "Cannot find module #{inspect pattern}"
      callback null, files
  catch error
    callback error

module.exports = need
