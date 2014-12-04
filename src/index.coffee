Q = require 'q'
Publisher = require './Publisher'
UDPReceiver = require './UDPReceiver'
TCPReceiver = require './TCPReceiver'
RELPReceiver = require './RELPReceiver'
fs = require 'q-io/fs'
fs.read process.argv[2]
.then (configJSON) ->
  config = JSON.parse configJSON
  publisher = new Publisher config.publisher.port, console
  udpReceiver = new UDPReceiver config.udpReceiver.port, console, publisher
  tcpReceiver = new TCPReceiver config.tcpReceiver.port, console, publisher
  relpReceiver = new RELPReceiver config.relpReceiver.port, console, publisher
  Q.all [
    udpReceiver.start(),
    tcpReceiver.start(),
    relpReceiver.start(),
    publisher.start()
  ]
.then ->
  console.log 'syslog-publisher started'
.done()
