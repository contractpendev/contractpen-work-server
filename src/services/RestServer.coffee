
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient
    @wss = opts.wss
    @identitySocketMap = {}

  sendAvailableCommandToClient: (socket) =>
    pending = await @asyncRedisClient.srandmember(RestServer.JOBS_PENDING_SET)
    if pending
      await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, pending)
      socket.send 'executeJob', pending

  setup: () =>
    @wss.on 'connection', (socket) =>
      socket.send('serverConnected', 'The server is connected')

      socket.on 'clientReadyToAcceptCommands', (clientIdentity) =>
        # @todo Clean up added records which were added more than n hours ago as this will grow too much
        @identitySocketMap[clientIdentity] = {
          addedTime: (new Date()).getTime()
          socket: socket
        } # Associated the id with the socket
        this.sendAvailableCommandToClient socket

      socket.on 'finishedJob', (message) =>
        console.log 'client finished a job'
        @asyncRedisClient.smove(RestServer.JOBS_AT_CLIENT, RestServer.JOBS_FINISHED, JSON.stringify(message.job))
        console.log 'do somnething with the result   ----- finished job on client'
        return

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
RestServer.JOBS_FINISHED = 'JOBS_FINISHED'

module.exports = RestServer