fs = require 'fs'
path = require 'path'
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

nodeModulesPaths = (start, opt) ->
  modules = opt.moduleDirectory || 'node_modules'
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

resolveDirectory = (p, opt) ->
  f = path.join p, 'index'
  package = path.join p, 'package.json'
  if exists package
    package = require package
    if package.main?
      f = path.resolve p, package.main

resolveModule = (from, to, opt) ->
  dirs = nodeModulesPaths from, opt
  for p in dirs
    if isDir p
      return resolve p, './' + to
  throw new Error "Cannot find module #{inspect to}"

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

need = (module, opt = {}, callback) ->
  if typeof opt is 'function'
    [callback, opt] = [opt, callback]
  opt.caller = getCaller()
  ret = switch typefor module
    when 'String'
      new Module module, opt
    when 'Function'
      new Module module(), opt
    when 'Array'
      new List module, opt
    when 'Object'
      new List module, opt
  callback? ret.send, ret.each, ret.pair
  ret

need.resolve = resolve
need.expand = expand

module.exports = need
