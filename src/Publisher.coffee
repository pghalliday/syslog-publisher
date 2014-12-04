Q = require 'q'
SocketIO = require 'socket.io'
http = require 'http'

class Publisher
  constructor: (@port, @logger) ->
    @server = http.createServer()
    @io = SocketIO @server

  start: =>
    @logger.log 'starting publisher on port ' + @port
    Q.ninvoke @server, 'listen', @port

  stop: =>
    Q.ninvoke @server, 'close'

  publish: (message) =>
    @logger.log message
    @io.emit 'message', message

module.exports = Publisher
