net = require 'net'
Q = require 'q'

class TCPReceiver
  constructor: (@port, @logger, publisher) ->
    @server = net.createServer (connection) =>
      connection.on 'data', (data) =>
        publisher.publish
          msg: data.slice(0, data.length - 1).toString()
          source: connection.remoteAddress
          protocol: 'tcp'

  start: =>
    @logger.log 'starting tcp receiver on port ' + @port
    Q.ninvoke @server, 'listen', @port

  stop: =>
    @server.close()

module.exports = TCPReceiver
