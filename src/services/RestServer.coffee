
class RestServer

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient
    @wss = opts.wss
    @identitySocketMap = {}

  # Randomly pick a command to send to a client and update redis state
  sendAvailableCommandToClient: (socket) =>
    pending = await @asyncRedisClient.srandmember(RestServer.JOBS_PENDING_SET)
    if pending
      await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, pending)
      socket.send 'executeJob', pending

  # Send the job to any random worker
  sendJobToAnyAvailableWorker: (jobString) =>
    availableWorkers = []
    # Find any random available worker
    for id, client of @identitySocketMap
      if client.workerState == RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
        availableWorkers.push
          id: id
          client: client
    if availableWorkers.length == 0
      return
    clientToSendTo = availableWorkers[Math.floor(Math.random() * availableWorkers.length)]
    # Update worker state
    @identitySocketMap[clientToSendTo.client.clientIdentity].workerState = RestServer.WORKER_EXECUTING_COMMAND
    @identitySocketMap[clientToSendTo.client.clientIdentity].lastStateChangeTime = (new Date()).getTime()
    # Send job to the worker
    clientToSendTo.client.socket.send 'executeJob', jobString
    # Update job state in Redis
    await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, jobString)

  # @todo Check the health of all state, eg, stale states reset
  healthCheck: () =>
    0

  setup: () =>
    @wss.on 'connection', (socket) =>
      socket.send('serverConnected', 'The server is connected')

      socket.on 'clientReadyToAcceptCommands', (clientIdentity) =>
        # @todo Clean up added records which were added more than n hours ago as this will grow too much
        @identitySocketMap[clientIdentity] = {
          clientIdentity: clientIdentity
          addedTime: (new Date()).getTime()
          socket: socket
          workerState: RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
          lastStateChangeTime: (new Date()).getTime()
        } # Associated the id with the socket
        this.sendAvailableCommandToClient socket

      socket.on 'finishedJob', (message) =>
        console.log 'client finished a job'
        @asyncRedisClient.smove(RestServer.JOBS_AT_CLIENT, RestServer.JOBS_FINISHED, JSON.stringify(message.job))
        result = message.result
        result.savedDateTime = (new Date()).getTime()
        @asyncRedisClient.sadd(RestServer.JOBS_RESULT, JSON.stringify(result))
        console.log 'do somnething with the result   ----- finished job on client'
        @identitySocketMap[message.workerId].workerState = RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
        @identitySocketMap[message.workerId].lastStateChangeTime = (new Date()).getTime()
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
      if (jobJson.targetWorkerId == null)
        await @sendJobToAnyAvailableWorker(jobString)
      res.json message: 'ok'

    console.log 'setup'

# Contains all submitted jobs
RestServer.JOBS_PENDING_SET = 'JOBS_PENDING_SET'
RestServer.JOBS_AT_CLIENT = 'JOBS_AT_CLIENT'
RestServer.JOBS_FINISHED = 'JOBS_FINISHED'

RestServer.JOBS_RESULT = 'JOBS_RESULT'

# Worker states
RestServer.WORKER_READY_TO_ACCEPT_COMMANDS = 'WORKER_READY_TO_ACCEPT_COMMANDS'
RestServer.WORKER_EXECUTING_COMMAND = 'WORKER_EXECUTING_COMMAND'

module.exports = RestServer