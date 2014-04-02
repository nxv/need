{ pairs
  typefor
  mergeAlias
  extendAlias
  neatenAlias } = require '../src/helper'

defaultOptions =
  async: no
  map: 123
  alias: [1,2,3]
  base: no
  log: no
  object: yes
  obj: no
  name: no
  ext: no

alias = [
  ['alias','map']
  ['object','obj']
  ['names','name']
  ['extensions','exts','ext'] ]

console.log mergeAlias defaultOptions, alias
console.log neatenAlias defaultOptions, alias
