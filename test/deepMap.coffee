{inspect} = require 'util'

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
      async.eachSeries keys
      , (key, cb) ->
        item = obj[key]; route = [key]
        iterator item, route, (err, newItem, newKey) ->
          iteratorCallback = (err, newItem, newKey) ->
            console.log '*Add:', newKey, key, newItem
            if newItem?
              newKey = newKey || key
              map[newKey] = newItem
            cb err
          console.log err, newItem, newKey, (err? or newItem? or newKey?)
          if err? or newItem?
            iteratorCallback err, newItem, newKey
          else
            console.log '>step in:', newKey, key
          # unless err? or newItem? or !newKey?
            deepMapAsync item
            , wrap(iterator, newKey? && newKey || key)
            , iteratorCallback
          # else iteratorCallback err, newItem, newKey
      , (err) -> callback err, map
    else iterator obj, null, callback
  deepMapAsync.typefor = typefor = (o) ->
    Object.prototype.toString.call(o)
    .match(/\[object (.*)\]/)[1]
  deepMapAsync.wrap =
  wrap = (iterator, route) ->
    (item, key, callback) ->
      route_ = [].concat (key? && key || []), route
      iterator item, route_, callback
  return deepMapAsync
)()

a =
  a: 'a'
  b: ['0b', '1b', a2b: 'a2b', b2b: -> 'b2b']
  c: 'c'
  d: {ad:'ad',bd:'bd', cd:['1cd', '2cd']}

arr = {a:{a:{a:'aaa'}}}

iterator = (item, route, callback) ->
  # console.log route
  key = "level#{route.length}-#{route[0]}"
  # route[0] = key
  console.log 'Change', route[0], 'to', key
  switch deepMapAsync.typefor(item)
    when 'Function'
      deepMapAsync item()
      , deepMapAsync
        .wrap(iterator, route)
      , callback
    when 'String'
      callback null, "done with #{inspect route}: #{item}.", key
    else callback null, null, key

deepMapAsync a, iterator, (err, result) ->
  console.log result

