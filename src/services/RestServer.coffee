
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
      # Insert task into Redis
      jobJson = req.body
      jobString = JSON.stringify(jobJson)
      await @asyncRedisClient.sadd('JOBS_SET', jobString)
      #myTest = await @asyncRedisClient.smembers('testset')
      #console.log(myTest)
      #console.log req.body.test
      res.json message: 'ok'

    console.log 'setup'

module.exports = RestServer