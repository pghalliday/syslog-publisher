dgram = require 'dgram'
net = require 'net'
SocketIOClient = require 'socket.io-client'
spawn = require('child_process').spawn
Q = require 'q'
fs = require 'q-io/fs'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
path = require 'path'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'

chai.should()
chai.use chaiAsPromised
chai.use sinonChai

tempDir = 'test/temp'
configFile = path.join tempDir, 'config.json'
config = '{"publisher":{"port":"8000"},"udpReceiver":{"port":"8001"},"tcpReceiver":{"port":"8002"},"relpReceiver":{"port":"8003"}}'
coffeeCommand = 'coffee'
syslogPublisherMain = 'src/index.coffee'
testUDPMessage = new Buffer 'This is a test'
testTCPMessage = new Buffer 'This is a test\n'

describe 'syslog-publisher', ->
  syslogPublisher = undefined
  stdoutSpy = undefined
  stderrSpy = undefined
  errorSpy = undefined
  socket = undefined

  before ->
    fs.makeTree tempDir
    .then ->
      fs.write configFile, config
    .then ->
      stdoutSpy = sinon.spy()
      stderrSpy = sinon.spy()
      errorSpy = sinon.spy()
      syslogPublisher = spawn coffeeCommand, [syslogPublisherMain, configFile]
      syslogPublisher.on 'error', errorSpy
      syslogPublisher.stdout.setEncoding 'utf8'
      syslogPublisher.stdout.on 'data', stdoutSpy
      syslogPublisher.stderr.setEncoding 'utf8'
      syslogPublisher.stderr.on 'data', stderrSpy
      Q.delay 1000
        .then ->
          socket = SocketIOClient 'http://localhost:8000'
          Q.ninvoke socket, 'on', 'connect'
        
  after ->
    socket.disconnect()
    syslogPublisher.kill()

  it 'should start', ->
    errorSpy.should.not.have.been.called
    stderrSpy.should.not.have.been.called
    stdoutSpy.callCount.should.eql 5
    stdoutSpy.should.have.been.calledWithExactly 'starting publisher on port 8000\n'
    stdoutSpy.should.have.been.calledWithExactly 'starting udp receiver on port 8001\n'
    stdoutSpy.should.have.been.calledWithExactly 'starting tcp receiver on port 8002\n'
    stdoutSpy.should.have.been.calledWithExactly 'starting relp receiver on port 8003\n'
    stdoutSpy.should.have.been.calledWithExactly 'syslog-publisher started\n'

  it 'should publish received UDP messages', ->
    deferred = Q.defer()
    socket.once 'message', deferred.resolve
    dgramSocket = dgram.createSocket 'udp4'
    Q.ninvoke dgramSocket, 'send', testUDPMessage, 0, testUDPMessage.length, 8001, 'localhost'
    .then ->
      dgramSocket.close()
    .done()
    deferred.promise.should.become
      msg: 'This is a test'
      source: '127.0.0.1'
      protocol: 'udp'

  it 'should publish received TCP messages', ->
    deferred = Q.defer()
    socket.once 'message', deferred.resolve
    tcpSocket = net.connect
      port: 8002
    , ->
      Q.ninvoke tcpSocket, 'write', testTCPMessage
      .then ->
        tcpSocket.end()
      .done()
    deferred.promise.should.become
      msg: 'This is a test'
      source: '::ffff:127.0.0.1'
      protocol: 'tcp'

  # TODO: figure out how to fake a RELP message
  it.skip 'should publish received RELP messages', ->
    deferred = Q.defer()
    socket.once 'message', deferred.resolve
    tcpSocket = net.connect
      port: 8003
    , ->
      Q.ninvoke tcpSocket, 'write', testTCPMessage
      .then ->
        tcpSocket.end()
      .done()
    deferred.promise.should.become
      msg: 'This is a test'
      source: '127.0.0.1'
      protocol: 'relp'
