need = require '../src/need'

need ['./*', '../**/{}/sd', 'coffee-script/*'], (err, files) ->
  console.log files