async = require 'async'

obj =
  a: 'a'
  b: 'b'
  c: 'c'

arr = [1,2,3,4]

async.map Object.keys(obj), (key, callback) ->
  item = obj[key]
  console.log item
  callback null, item
, (err, results) ->
  console.log results