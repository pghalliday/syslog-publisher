dgram = require 'dgram'
Q = require 'q'

class UDPReceiver
  constructor: (@port, @logger, publisher) ->
    @server = dgram.createSocket 'udp4'
    @server.on 'message', (msg, rinfo) ->
      publisher.publish
        msg: msg.toString()
        source: rinfo.address
        protocol: 'udp'

  start: =>
    @logger.log 'starting udp receiver on port ' + @port
    Q.ninvoke @server, 'bind', @port

  stop: =>
    @server.close()

module.exports = UDPReceiver
