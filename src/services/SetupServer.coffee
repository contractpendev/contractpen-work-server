
Entities = require('html-entities').AllHtmlEntities
Handlebars = require 'handlebars'
helpers = require('handlebars-helpers')(handlebars: Handlebars)
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
graphQlRequest = require 'graphql-request'
program = require 'commander'
path = require 'path'

class SetupServer

  constructor: (opts) ->
    @g = opts.graph

  setup: () ->
    console.log 'hi'

  doNothing: (error) -> 0

module.exports = SetupServer


