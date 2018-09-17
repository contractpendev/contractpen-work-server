
Entities = require('html-entities').AllHtmlEntities
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
graphQlRequest = require 'graphql-request'
program = require 'commander'
path = require 'path'

class SetupServer

  constructor: (opts) ->
    @g = opts.graph
    @container = opts.container

  setup: () ->
    restServer = @container.resolve 'RestServer'
    restServer.setup()


  doNothing: (error) -> 0

module.exports = SetupServer


