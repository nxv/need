glob = require 'glob'

f = glob './*', (er, files) ->
  console.log arguments

console.log f