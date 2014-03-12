Q = require 'q'

typefor = (o) ->
  Object.prototype.toString.call(o)
  .match(/\[object (.*)\]/)[1]

wrap = (func, route, obj) ->
  (_el, _route) ->
    _route = [].concat _route, route
    func _el, _route, obj

deepMap = (obj, func) ->
  switch typefor obj
    when 'Array'
      Q().then ->
        obj.map (el, index) ->
          route = [index]
          func el, route, obj
          .spread (newEl) ->
            return newEl if newEl?
            deepMap el, wrap func, route, el
      .all()
    when 'Object'
      map = {}
      Q().then ->
        keys = Object.keys obj
        keys.map (key) ->
          el = obj[key]
          route = [key]
          func el, route, obj
          .spread (newEl, newKey) ->
            # console.log 'catch:', arguments...
            _key = newKey? && newKey || key
            _route = [_key]
            if newEl?
              return map[_key] = newEl
            deepMap el, wrap func, _route, el
      .all()
      .then -> map
    else
      Q().then ->
        func obj

iterator = (el, route, parent) ->
  console.log route, el
  deferred = Q.defer()
  newKey = route[0] + 'OK'
  _route = [].concat newKey, route[1..]
  switch typefor el
    when 'Function'
      _el = el()
      deepMap _el
      , wrap iterator, _route, _el
      .then (results) ->
        deferred.resolve [results, newKey]
    when 'String'
      newEl = el + ' OK.'
      setTimeout ->
        deferred.resolve [newEl, newKey]
    else
      deferred.resolve []
  deferred.promise

a =
  a: 'a'
  b: ['0b', '1b', a2b: 'a2b', b2b: -> 'b2b']
  c: 'c'
  d: {ad:'ad',bd:'bd', cd:['1cd', '2cd']}

deepMap a, iterator
.then console.log



