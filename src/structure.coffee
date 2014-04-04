{ pairs
  copy
  extend
  typefor
  indexOfHead
  mergeAlias
  neatenAlias
  getCaller } = require './helper'

optionAlias =   [
  ['alias'     , 'map' ]
  ['object'    , 'obj' ]
  ['names'     , 'name']
  ['extensions', 'exts'
               , 'ext' ] ]

mergeOptionAlias = (options) ->
  mergeAlias options, optionAlias

neatenOptionAlias = (options) ->
  neatenAlias options, optionAlias

setBase = (options, offset = 0) ->
  options.caller = getCaller offset - 1
  unless options.base
    options.base = options.caller.path

Need = ->
  need = (patterns, options, onFulfilled) ->
    setBase need.options
    opts = mergeOptionAlias need.options
    extend opts, mergeOptionAlias options
    opts = neatenOptionAlias opts

init = ->
  construct
    async: no
    alias: []
    base: no
    log: no
    object: no
    names: no
    extensions: pairs require.extensions

construct = (defaults) ->
  need = new Need()
  need.options =
  need.opts    = 
  need.opt     = neatenOptionAlias defaults
  methods need
  need

methods = (need) ->

  apply = (options = {}) ->
    defaults = mergeOptionAlias need.options
    extend defaults, mergeOptionAlias options
    neatenOptionAlias defaults

  renew = (options) ->
    construct apply options

  need.configure =
  need.config    =
  need.defaults  =
  need.default   = (options) ->
    if options?
      renew options
    else init()

  need.async = (patterns, options) ->
    if arguments.length
      options = copy options
      setBase options if options?
      need arguments...
    else renew async: on

  need.set    =
  need.define =
  need.def    = (name, map) ->
    if map?
      alias = [[name, map]]
      for i in need.options.alias
        i[0] == name || alias.push i
      renew {alias}
    else if name?
      switch typefor name
        when 'object'
          need.set pairs name
        when 'array'
          ret = need
          for i in name
            [a, b] = [].concat i
            ret = ret.set a, b
          ret
        when 'function'
          renew alias: need.options.
            alias.concat name
        else need
    else need

  need.unset  =
  need.remove =
  need.rm     = (name) ->
    alias = [].concat need.options.alias
    if typefor(name) is 'number'
      return need unless ~name
      alias.splice name, 1
      renew {alias}
    else
      need.unset indexOfHead name, alias

  need.register =
  need.reg = (ext, handler, index) ->
    if handler?
      exts = [].concat need.options.exts
      if ~i = indexOfHead ext, exts
        exts.splice i, 1
      index = exts.length unless index?
      exts.splice index, 0, [ext, handler]
      renew {exts}
    else if ext?
      switch typefor ext
        when 'array'
          ret = need
          for i in ext
            ret = ret.reg i...
          ret
        when 'object'
          ext = for k, v of ext
            [k].concat [].concat v
          need.reg ext
        else need
    else need

  need.unregister =
  need.unreg = (ext) ->
    exts = [].concat need.options.exts
    if typefor(ext) is 'number'
      return need unless ~ext
      exts.splice ext, 1
      renew {exts}
    else
      need.unregister indexOfHead ext, exts

module.exports = init()