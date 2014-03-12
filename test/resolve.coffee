need = require '../src/need'

need ['./*', '../*', 'coffee-script/**/*.js'], (err, files) ->
  console.log files