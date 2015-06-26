syslog-publisher
================

Receive syslog messages over UDP/TCP/RELP and publishe them to connected Socket.IO clients

Prerequisites
-------------

- [Node.js](https://nodejs.org/)

Usage
-----

```
npm start
```

Integration
-----------

### Forward syslog messages from your syslog daemon

- Forward syslog messages over UDP to the UDP port (default `8001`)
- Forward syslog messages over TCP to the TCP port (default `8002`)
- Forward syslog messages over RELP to the RELP port (default `8003`)

### Connect Socket.IO clients to receive syslog messages

Connect a Socket.IO client to the publisher port (default `8000`)

Listen for `message` events. The event payload will be structured as follows

```javascript
{
  msg: '...',         // The raw message
  source: '1.2.3.4',  // The source IP
  protocol: 'udp'     // The forwarding protocol
}
```

### Using different ports

Override ports in `config.json` as desired

Contributing
------------

Add tests for changes and run

```
npm test
```

LICENSE
-------

Copyright &copy; 2015 Peter Halliday  
Licensed under the MIT license.

[![Donate Bitcoins](http://i.imgur.com/b5BZsFH.png)](bitcoin:17LtnRG4WxRLYBWzrBoEKP3F7fZx8vcAsK?amount=0.01&label=grunt-mocha-test)

[17LtnRG4WxRLYBWzrBoEKP3F7fZx8vcAsK](bitcoin:17LtnRG4WxRLYBWzrBoEKP3F7fZx8vcAsK?amount=0.01&label=grunt-mocha-test)
