
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient

  setup: () ->
    # Task is submitted and will be worked on by a worker nodejs client
    # Task is defined in JSON structure
    # HTTP POST TO http://localhost:3050/api/submitTask with body raw JSON (application/json)
    @expressRouter.post '/submitTask', (req, res) =>
      await @asyncRedisClient.set('key', 'value')
      console.log req.body.test
      res.json message: 'zzhooray! welcome to our api!'
      return
    console.log 'setup'

module.exports = RestServer