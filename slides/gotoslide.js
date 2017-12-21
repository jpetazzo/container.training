#!/usr/bin/env node
var io = require('socket.io-client');
var socket = io('http://localhost:3000');
socket.emit('slide change', process.argv[2], function () {
    socket.close();
});
