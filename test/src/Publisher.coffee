SocketIOClient = require 'socket.io-client'
Q = require 'q'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'

sinon = require 'sinon'
sinonChai = require 'sinon-chai'

chai.should()
chai.use chaiAsPromised
chai.use sinonChai

port = 8002
testMessage =
  msg: 'This is a test'
  source: '1.2.3.4'

Publisher = require '../../src/Publisher'

describe 'Publisher', ->
  publisher = undefined
  socket1 = undefined
  socket2 = undefined
  logger =  Object.create null

  before ->
    logger.log = sinon.spy()
    publisher = new Publisher port, logger
    publisher.start()

  after ->
    publisher.stop()

  afterEach ->
    if socket1
      socket1.disconnect()
      socket1 = undefined
    if socket2
      socket2.disconnect()
      socket2 = undefined

  it 'should start', ->
    logger.log.should.have.been.called.once
    logger.log.args[0].should.eql ['starting publisher on port 8002']

  it 'should publish messages to socket.io connections', ->
    socket1 = SocketIOClient 'http://localhost:8002'
    socket2 = SocketIOClient 'http://localhost:8002'
    Q.all [
      Q.ninvoke(socket1, 'on', 'connect'),
      Q.ninvoke(socket2, 'on', 'connect')
    ]
    .then ->
      publisher.publish testMessage
    .done()
    deferred1 = Q.defer()
    deferred2 = Q.defer()
    socket1.on 'message', (message) ->
      deferred1.resolve message
    socket2.on 'message', (message) ->
      deferred2.resolve message
    Q.all [
      deferred1.promise.should.eventually.deep.eql(testMessage),
      deferred2.promise.should.eventually.deep.eql(testMessage)
    ]
