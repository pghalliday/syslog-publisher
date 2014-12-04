dgram = require 'dgram'
Q = require 'q'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'

sinon = require 'sinon'
sinonChai = require 'sinon-chai'

chai.should()
chai.use chaiAsPromised
chai.use sinonChai

port = 8003
testMessage = new Buffer 'This is a test'

UDPReceiver = require '../../src/UDPReceiver'

describe 'UDPReceiver', ->
  receiver = undefined
  socket = undefined
  logger =  Object.create null
  publisher = Object.create null

  before ->
    logger.log = sinon.spy()
    publisher.publish = (msg, rinfo) ->
      publisher.publishMethod msg, rinfo
    receiver = new UDPReceiver port, logger, publisher
    receiver.start()

  after ->
    receiver.stop()

  it 'should start', ->
    logger.log.should.have.been.called.once
    logger.log.args[0].should.eql ['starting udp receiver on port 8003']

  it 'should forward udp messages to the publisher', ->
    deferred = Q.defer()
    publisher.publishMethod = sinon.spy (message) ->
      message.msg.should.eql 'This is a test'
      message.source.should.eql '127.0.0.1'
      message.protocol.should.eql 'udp'
      deferred.resolve()
    socket = dgram.createSocket 'udp4'
    Q.ninvoke socket, 'send', testMessage, 0, testMessage.length, 8003, 'localhost'
    .then ->
      socket.close()
    .done()
    deferred.promise.should.eventually.be.fulfilled
