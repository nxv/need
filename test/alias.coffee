{ pairs
  typefor
  mergeAlias
  extendAlias
  neatenAlias } = require '../src/helper'

defaultOptions =
  async: no
  alias: []
  base: no
  log: no
  object: no
  names: no
  extensions: no

alias = [
  ['alias','map']
  ['object','obj']
  ['names','name']
  ['extensions','exts','ext'] ]

console.log mergeAlias defaultOptions, alias
