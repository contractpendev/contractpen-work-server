
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient
    @wss = opts.wss

  sendAvailableCommandToClient: (socket) =>
    pending = await @asyncRedisClient.srandmember(RestServer.JOBS_PENDING_SET)
    if pending
      await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, pending)
      socket.send 'executeJob', pending

  setup: () =>
    @wss.on 'connection', (socket) =>
      console.log 'Socket is connected'
      socket.send('serverConnected', 'The server is connected')
      socket.on 'clientReadyToAcceptCommands', (message) =>
        console.log 'clientReadyToAcceptCommands received from the client means that we can send a command to this client'
        console.log(message)
        this.sendAvailableCommandToClient socket
      socket.on 'finishedJob', (message) =>
        console.log 'client finished a job'

    # Task is submitted and will be worked on by a worker nodejs client
    # Task is defined in JSON structure
    # HTTP POST TO http://localhost:3050/api/submitTask with body raw JSON
    @expressRouter.post '/submitTask', (req, res) =>
      # Insert task into Redis
      jobJson = req.body
      #now = new Date()
      #jobJson.dateTimeCreated = now.getTime()
      jobString = JSON.stringify(jobJson)
      console.log 'adding job string to'
      console.log jobString
      await @asyncRedisClient.sadd(RestServer.JOBS_PENDING_SET, jobString)
      res.json message: 'ok'

    console.log 'setup'

# Contains all submitted jobs
RestServer.JOBS_PENDING_SET = 'JOBS_PENDING_SET'
RestServer.JOBS_AT_CLIENT = 'JOBS_AT_CLIENT'

module.exports = RestServer