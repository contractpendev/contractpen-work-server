
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient
    @wss = opts.wss

  setup: () ->
    @wss.on 'connection', (socket) ->
      console.log 'Socket is connected'
      socket.send('serverConnected', 'The server is connected')
      socket.on 'clientReadyToAcceptCommands', (message) ->
        console.log 'clientReadyToAcceptCommands received from the client means that we can send a command to this client'
        console.log(message)

    # Task is submitted and will be worked on by a worker nodejs client
    # Task is defined in JSON structure
    # HTTP POST TO http://localhost:3050/api/submitTask with body raw JSON
    @expressRouter.post '/submitTask', (req, res) =>
# Insert task into Redis
      jobJson = req.body
      console.log jobJson
      jobString = JSON.stringify(jobJson)
      console.log 'adding job string to'
      console.log jobString
      await @asyncRedisClient.sadd(RestServer.JOBS_PENDING_SET, jobString)
      res.json message: 'ok'

    console.log 'setup'

# Contains all submitted jobs
RestServer.JOBS_PENDING_SET = 'JOBS_PENDING_SET'

module.exports = RestServer