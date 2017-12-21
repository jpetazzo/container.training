#!/usr/bin/env node
var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res){
  res.send('<h1>Hello world</h1>');
});

app.use(express.static('.'));

io.on('connection', function(socket){
  console.log('a client connected');
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
