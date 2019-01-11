
class RestServer

  # @todo Tasks to do
  # @todo 1. Each socket has an id identifier, so therefore we do not need a guid on the client side, just use the socket id

  constructor: (opts) ->
    @container = opts.container
    @expressRouter = opts.expressRouter
    @g = opts.graph
    @asyncRedisClient = opts.asyncRedisClient
    @wss = opts.wss
    @identitySocketMap = {}

  # Randomly pick a command to send to a client and update redis state
  sendAvailableCommandToClient: (socket, clientIdentity) =>
    # Precondition: Is the worker available
    if @identitySocketMap[clientIdentity].workerState == RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
      pending = await @asyncRedisClient.srandmember(RestServer.JOBS_PENDING_SET)
      if pending
        console.log 'sending an available command to client'
        # Update worker state
        @identitySocketMap[clientIdentity].workerState = RestServer.WORKER_EXECUTING_COMMAND
        @identitySocketMap[clientIdentity].lastStateChangeTime = (new Date()).getTime()
        await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, pending)
        socket.send 'executeJob', pending
        console.log 'sent'

  # Send the job to any random worker
  sendJobToAnyAvailableWorker: (jobString) =>
    availableWorkers = []
    # Find any random available worker
    for id, client of @identitySocketMap
      if client.workerState == RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
        availableWorkers.push
          id: id
          client: client
    console.log 'there are n available workers ' + availableWorkers.length
    if availableWorkers.length == 0
      return
    clientToSendTo = availableWorkers[Math.floor(Math.random() * availableWorkers.length)]
    # Update worker state
    @identitySocketMap[clientToSendTo.client.clientIdentity].workerState = RestServer.WORKER_EXECUTING_COMMAND
    @identitySocketMap[clientToSendTo.client.clientIdentity].lastStateChangeTime = (new Date()).getTime()
    # Update job state in Redis
    await @asyncRedisClient.smove(RestServer.JOBS_PENDING_SET, RestServer.JOBS_AT_CLIENT, jobString)
    # Send job to the worker
    clientToSendTo.client.socket.send 'executeJob', jobString

  # @todo Check the health of all state, eg, stale states reset
  healthCheck: () =>
    0

  setup: () =>
    @wss.on 'connection', (socket) =>
      socket.send('serverConnected', 'The server is connected')
      #console.log socket.id

      socket.on 'disconnect', (code, reason) =>
        idToRemove = null
        for id, client of @identitySocketMap
          idToRemove = id if client.socket.id == socket.id
        delete @identitySocketMap[idToRemove]
        # your code to execute on disconnect event
        return

      # error event is called when something went wrong with socket
      #socket.on 'error', (err) ->
      #  # your code to execute on error event
      #  return

      socket.on 'clientReadyToAcceptCommands', (clientIdentity) =>
        console.log 'clientReadyToAcceptCommands received for ' + clientIdentity
        # @todo Clean up added records which were added more than n hours ago as this will grow too much
        @identitySocketMap[clientIdentity] = {
          clientIdentity: clientIdentity
          addedTime: (new Date()).getTime()
          socket: socket
          workerState: RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
          lastStateChangeTime: (new Date()).getTime()
        } # Associated the id with the socket
        this.sendAvailableCommandToClient socket, clientIdentity

      socket.on 'finishedJob', (message) =>
        console.log 'client finished a job'
        result = message
        result.savedDateTime = (new Date()).getTime()
        console.log message.job
        console.log JSON.stringify(message.job)
        console.log '...'
        @asyncRedisClient.smove(RestServer.JOBS_AT_CLIENT, RestServer.JOBS_FINISHED, JSON.stringify(message.job))
        @asyncRedisClient.sadd(RestServer.JOBS_RESULT, JSON.stringify(result))
        if message.job.transactionId
          @asyncRedisClient.publish(message.job.transactionId, JSON.stringify(result))
        console.log 'do somnething with the result   ----- finished job on client'
        @identitySocketMap[message.workerId].workerState = RestServer.WORKER_READY_TO_ACCEPT_COMMANDS
        @identitySocketMap[message.workerId].lastStateChangeTime = (new Date()).getTime()
        # See if there are any available jobs for this worker to do
        @sendAvailableCommandToClient socket, message.workerId
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