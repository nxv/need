{ pairs
  copy
  typefor
  mergeAlias
  neatenAlias } = require './helper'

defaultOptions =
  async: no
  alias: []
  base: no
  log: no
  object: no
  names: no
  extensions: no

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

Need = (patterns, options, onFulfilled) ->

init = ->
  construct defaultOptions

construct = (defaults) ->
  need = new Need
  need.options =
  need.opts    = 
  need.opt     = neatenOptionAlias defaults
  methods need
  need

methods = (need) ->

  apply = (options = {}) ->
    defaults = mergeOptionAlias need.options
    defaults = copy mergeOptionAlias options
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

  need.async = ->
    if arguments.length
      need arguments...
    else renew async: yes

  need.set    =
  need.define =
  need.def    = (name, map) ->
    switch arguments.length
      when 2
        alias = for i in need.options.alias
          i[0] == name && [name, map] || i
        renew {alias}
      when 1
        switch typefor name
          when 'object'
            need.set pairs name
          when 'array'
            ret = need
            for [a, b] in name
              ret = ret a, b
            ret
          when 'function'
            renew alias: need.options
              .alias.concat [name]
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
      need.unset alias.indexOf name


module.exports = init()