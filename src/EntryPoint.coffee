
Comedy = require 'comedy'
Awilix = require 'awilix'
Setup = require './Setup'

start = ->
  setupServer = Setup.container.resolve 'SetupServer'
  setupServer.setup()

start()

