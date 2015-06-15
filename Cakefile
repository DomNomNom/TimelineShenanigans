{exec} = require 'child_process'

task 'sbuild', 'Builds the project', ->
  exec 'coffee --compile --map --output compiledCoffeeScript .', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
