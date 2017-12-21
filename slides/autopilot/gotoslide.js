#!/usr/bin/env node

/* Expects a slide number as first argument.
 * Will connect to the local pub/sub server,
 * and issue a "go to slide X" command, which
 * will be sent to all connected browsers.
 */

var io = require('socket.io-client');
var socket = io('http://localhost:3000');
socket.on('connect_error', function(){ 
  console.log('connection error');
  socket.close();
});
socket.emit('slide change', process.argv[2], function(){
  socket.close();
});
