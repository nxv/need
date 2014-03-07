Q = require 'q'
fs = require 'fs'
glob = require 'glob'
path = require 'path'
async = require 'async'
{inspect} = require 'util'

exists = fs.existsSync
globAsync = Q.denodeify glob

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

regEscape = (str) ->
  str.replace /[-\/\\^$*+?.()|[\]{}]/g, '\\$&'

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

expand = (left, middle, right = '') ->
  ret = []
  if 0 < left.indexOf '*'
    [n, l, r] = left.match /^([^\*]*)\*(.*)$/
    [n, l, ll] = l.match /^(.*\/)?(.*)$/
    [n, rr, r] = r.match /^([^\/]*)(.*)$/
    m = new RegExp "^#{regEscape ll}[^\\/]*#{regEscape rr}$"
    return expand l, m, r
  unless middle?
    return left
  unless isDir left
    return ret
  dirOnly = right[0] == path.sep
  files = fs.readdirSync(left)
    .filter((s) -> middle.test(s) && !(dirOnly && !isDir(s)))
    .map (s) -> path.join left, s, right
  for f in files
    ret = ret.concat expand f
  ret

resolveFile = (p, opt) ->
  {extensions} = require
  extensions.concat opt.extensions || []
  if hasExt p, extensions
    extensions.push ''
  for ext in extensions
    f = p + ext
    if isFile f then f else continue

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


resolve = (from, to, opt = {}) ->
  if to.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
  else
    return resolveModule from, to, opt
  expand path.resolve from, to


class Module
  constructor: (@path, @opt) ->
    @load()
  load: ->




class List
  constructor: (module, @opt) ->
    @pair = {}
    switch typefor module
      when 'Object'
        @add v, k for k, v of module
      when 'Array'
        @add v for v in module
  add: (module, name) ->
    p = resolve @opt.caller.path, module, @opt
    for m in p
      val = new Module m
      name = name || val.getName() || m
      @pair[name] = val

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

need = (pattern, opt, callback) ->
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
  pattern = flatten(pattern)
  # .map (p) ->
  #   if p.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
  #     return path.resolve opt.path, p
  #   for m in opt.paths
  #     path.join m, p
  if opt.sync
    loadSync pattern, opt
  else
    loadAsync pattern, opt, callback
    # console.log pattern
    # Q.all(pattern)
    #   .then(globAsync(opt.glob))
    #   .spread(flattenAsync)
    #   .all(loadAsync)
    #   .spread(flattenAsync)
    #   .nodeify(callback)

loadAsync = (pattern, opt, callback) ->
  console.log pattern
  async.map pattern, globAsync(opt), callback

globAsync = (opt) ->
  (pattern, callback) ->
    if pattern.match /^(?:\.\.?\/|\/|([A-Za-z]:)?\\)/
      glob pattern, opt.glob, (err, files) ->
        return callback err if err
        files = files.map (f) ->
          path.resolve opt.path, f
        callback null, flatten files
    else
      resolveModuleAsync opt.path, pattern, opt.glob, callback

resolveModuleAsync = (from, to, opt, callback) ->
  opt = Object.create opt
  paths = paths || getPaths from
  async.detectSeries paths.reverse(), (p, callback) ->
    opt.cwd = p
    glob to, opt, (err, files) ->
      callback files
  , (module) ->
    unless module
      return callback new Error "Cannot find module #{inspect to}"
    callback null, path.resolve module, to

# globAsync = (opt) ->
#   (pattern) ->
#     console.log pattern
#     globAsync pattern, opt

flattenAsync = (arg...) ->
  flatten arg

# loadAsync = (p) ->
#   try
#     require p
#   catch e


need.resolve = resolve
need.expand = expand

module.exports = need
