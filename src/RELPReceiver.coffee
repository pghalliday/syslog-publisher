relp = require 'relp'
net = require 'net'
Q = require 'q'
Server = relp.Server

class RELPReceiver
  constructor: (@port, @logger, publisher) ->
    @netServer = net.createServer (connection) =>
    @server = new Server
      server: @netServer
    @server.on 'message', (message) =>
      publisher.publish
        msg: message.body
        source: @server.sockets[message.socketId].remoteAddress
        protocol: 'relp'
      @server.ack message

  start: =>
    @logger.log 'starting relp receiver on port ' + @port
    Q.ninvoke @netServer, 'listen', @port

  stop: =>
    @server.close()

module.exports = RELPReceiver
