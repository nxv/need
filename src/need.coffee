fs = require 'fs'
glob = require 'glob'
path = require 'path'
async = require 'async'
{inspect} = require 'util'

exists = fs.existsSync

isFile = (p) ->
  exists(p) and fs.statSync(p).isFile()

isDir = (p) ->
  exists(p) and fs.statSync(p).isDirectory()

# Tell if a file path has an extension in a list
hasExt = (p, exts) ->
  exts = [].concat exts
  for ext in exts
    return true if p[-ext.length..] == ext

typefor = (o) ->
  Object.prototype.toString.call(o)
  .match(/\[object (.*)\]/)[1]

# regEscape = (str) ->
#   str.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

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

# expand = (left, middle, right = '') ->
#   ret = []
#   if 0 < left.indexOf '*'
#     [n, l, r] = left.match /^([^\*]*)\*(.*)$/
#     [n, l, ll] = l.match /^(.*\/)?(.*)$/
#     [n, rr, r] = r.match /^([^\/]*)(.*)$/
#     m = new RegExp "^#{regEscape ll}[^\\/]*#{regEscape rr}$"
#     return expand l, m, r
#   unless middle?
#     return left
#   unless isDir left
#     return ret
#   dirOnly = right[0] == path.sep
#   files = fs.readdirSync(left)
#     .filter((s) -> middle.test(s) && !(dirOnly && !isDir(s)))
#     .map (s) -> path.join left, s, right
#   for f in files
#     ret = ret.concat expand f
#   ret

# resolveFile = (p, opt) ->
#   {extensions} = require
#   extensions.concat opt.extensions || []
#   if hasExt p, extensions
#     extensions.push ''
#   for ext in extensions
#     f = p + ext
#     if isFile f then f else continue

# resolveDirectory = (p, opt) ->
#   f = path.join p, 'index'
#   package = path.join p, 'package.json'
#   if exists package
#     package = require package
#     if package.main?
#       f = path.resolve p, package.main

# resolveModule = (from, to, paths) ->
#   paths = paths || getPaths from
#   for p in paths
#     if isDir p
#       return resolve p, './' + to
#   throw new Error "Cannot find module #{inspect to}"


# resolve = (from, to, opt = {}) ->
#   if to.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
#   else
#     return resolveModule from, to, opt
#   expand path.resolve from, to


# class Module
#   constructor: (@path, @opt) ->
#     @load()
#   load: ->




# class List
#   constructor: (module, @opt) ->
#     @pair = {}
#     switch typefor module
#       when 'Object'
#         @add v, k for k, v of module
#       when 'Array'
#         @add v for v in module
#   add: (module, name) ->
#     p = resolve @opt.caller.path, module, @opt
#     for m in p
#       val = new Module m
#       name = name || val.getName() || m
#       @pair[name] = val

flatten = (arg, depth = Infinity) ->
  if depth < 0
    return [arg]
  switch typefor arg
    when 'Function'
      flatten arg(), -- depth
    when 'Array', 'Object'
      ret = for k, v of arg
        flatten v, -- depth
      [].concat ret...
    else [arg]

need = (patterns, opt, callback) ->
  if typeof opt is 'function'
    [callback, opt] = [opt, callback]
  opt = Object.create opt || {}
  opt.caller = getCaller()
  opt.path = opt.caller.path
  opt.paths = getPaths opt.path
  opt.sync = !callback
  opt.glob =
    cwd: opt.path
    mark: on
    silent: on
    sync: opt.sync
  # patterns = flatten patterns
  # .map (p) ->
  #   if p.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
  #     return path.resolve opt.path, p
  #   for m in opt.paths
  #     path.join m, p
  if opt.sync
    loadSync patterns, opt
  else
    loadAsync patterns, opt, callback
    # console.log patterns
    # Q.all(patterns)
    #   .then(globAsync(opt.glob))
    #   .spread(flattenAsync)
    #   .all(loadAsync)
    #   .spread(flattenAsync)
    #   .nodeify(callback)

###*
 * Iterate and map recursively into an object
 * @param  {Object}   obj      the object to iterate
 * @param  {Function} iterator(item, route, callback)
 * A function to apply to each item in the array.
 * The iterator is passed a callback(err, newItem, newKey)
 * If callback() is called without arguments, the iteration
 * go in deeper inside the current item. Otherwise if newItem
 * or newKey is defined, the iteration on the currenct route
 * would stop, and the current item would be replaced.
 * @param  {Function} callback(err, results)
 * A callback which is called after all the iterator 
 * functions have finished, or an error has occurred.
###
deepMapAsync = ( ->
  async = require 'async'
  deepMapAsync = (obj, iterator, callback) ->
    type = typefor obj
    if type in ['Object', 'Array']
      map = {}
      keys = type == 'Object' &&
        Object.keys(obj) ||
        [0...obj.length]
      async.each keys
      , (key, cb) ->
        item = obj[key]; route = [key]
        iterator item, route, (err, newItem, newKey) ->
          iteratorCallback = (err, newItem, newKey) ->
            if newItem?
              newKey = newKey || key
              map[newKey] = newItem
            cb err
          unless err? or newItem? or newKey?
            deepMapAsync item
            , wrap(iterator, key)
            , iteratorCallback
          else iteratorCallback err, newItem, newKey
      , (err) -> callback err, map
    else iterator obj, null, callback
  deepMapAsync.wrap =
  wrap = (iterator, route) ->
    (item, key, callback) ->
      route_ = [].concat (key? && key || []), route
      iterator item, route_, callback
  return deepMapAsync
)()

loadAsync = (patterns, opt, callback) ->
  deepMapAsync patterns, patternIterator, callback

patternIterator = (item, route, callback) ->
  if typefor(item) is 'Function'
    deepMapAsync item()
    , deepMapAsync.wrap(patternIterator, route)
    , callback
  else if typefor(item) is 'String'
    if item.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
      # In relative file system
      traceInFilesAsync item, opt, callback
    else
      # In module paths
      traceInModulesAsync item, opt, callback
    callback null, "done with #{inspect route}: #{item}."
  else callback()

# loadAsync = (patterns, opt, callback) ->
#   console.log patterns
#   async.map patterns, (pattern, callback) ->
#     if pattern.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
#       # In relative file system
#       traceInFilesAsync pattern, opt, callback
#     else
#       # In module paths
#       traceInModulesAsync pattern, opt, callback
#   , (err, files) ->
#     callback err, flatten files

_requireAsync = (p) ->


# globAsync = (opt) ->
#   (pattern, callback) ->
#     if pattern.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
#       glob pattern, opt.glob, (err, files) ->
#         return callback err if err
#         callback null, files.map (f) ->
#           path.resolve opt.path, f
#     else
#       traceInModulesAsync pattern, opt, callback

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
  # async.detectSeries paths.reverse(), (p, callback) ->
  #   opt.cwd = p
  #   glob to, opt, (err, files) ->
  #     callback files
  # , (module) ->
  #   unless module
  #     return callback new Error "Cannot find module #{inspect to}"
  #   callback null, path.resolve module, to

# globAsync = (opt) ->
#   (pattern) ->
#     console.log pattern
#     globAsync pattern, opt

# flattenAsync = (arg...) ->
#   flatten arg

# loadAsync = (p) ->
#   try
#     require p
#   catch e


module.exports = need
