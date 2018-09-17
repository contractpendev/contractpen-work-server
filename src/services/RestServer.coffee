
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph

  setup: () ->
    @expressRouter.get '/', (req, res) ->
      res.json message: 'zzhooray! welcome to our api!'
      return
    console.log 'setup'

module.exports = RestServer