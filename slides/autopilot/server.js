#!/usr/bin/env node

/* This is a very simple pub/sub server, allowing to
 * remote control browsers displaying the slides.
 * The browsers connect to this pub/sub server using
 * Socket.IO, and the server tells them which slides
 * to display.
 *
 * The server can be controlled with a little CLI,
 * or by one of the browsers.
 */

var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res){
  res.send('container.training autopilot pub/sub server');
});

/* Serve remote.js from the current directory */
app.use(express.static('.'));

/* Serve slides etc. from current and the parent directory */
app.use(express.static('..'));

io.on('connection', function(socket){
  console.log('a client connected: ' + socket.handshake.address);
  socket.on('slide change', function(n, ack){
    console.log('slide change: ' + n);
    socket.broadcast.emit('slide change', n);
    if (typeof ack === 'function') {
      ack();
    }
  });
});

http.listen(3000, function(){
  console.log('listening on *:3000');
});
