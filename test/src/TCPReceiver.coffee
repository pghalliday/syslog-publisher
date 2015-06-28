net = require 'net'
Q = require 'q'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'

sinon = require 'sinon'
sinonChai = require 'sinon-chai'

chai.should()
chai.use chaiAsPromised
chai.use sinonChai

port = 8004
testMessage = new Buffer 'This is a test\n'

TCPReceiver = require '../../src/TCPReceiver'

describe 'TCPReceiver', ->
  receiver = undefined
  socket = undefined
  logger =  Object.create null
  publisher = Object.create null

  before ->
    logger.log = sinon.spy()
    publisher.publish = (msg, rinfo) ->
      publisher.publishMethod msg, rinfo
    receiver = new TCPReceiver port, logger, publisher
    receiver.start()

  after ->
    receiver.stop()

  it 'should start', ->
    logger.log.should.have.been.called.once
    logger.log.args[0].should.eql ['starting tcp receiver on port 8004']

  it 'should forward tcp messages to the publisher after stripping the trailing new line', ->
    deferred = Q.defer()
    publisher.publishMethod = sinon.spy (message) ->
      message.msg.should.eql 'This is a test'
      message.source.should.eql '::ffff:127.0.0.1'
      message.protocol.should.eql 'tcp'
      deferred.resolve()
    socket = net.connect
      port: 8004
    , ->
      Q.ninvoke socket, 'write', testMessage
      .then ->
        socket.end()
      .done()
    deferred.promise.should.eventually.be.fulfilled
