
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @g = opts.graph

  setup: () ->
    console.log @container
    console.log 'setup'

module.exports = RestServer