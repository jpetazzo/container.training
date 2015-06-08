var express = require('express');
var app = express();

app.get('/', function (req, res) {
    res.redirect('/index.html');
});

app.get('/json', function (req, res) {
    redis.hlen('wallet', function (err, coins) {
        redis.get('hashes', function (err, hashes) {
            var now = Date.now() / 1000;
            res.json( {
                coins: coins,
                hashes: hashes,
                now: now
            });
        });
    });
});

app.use(express.static('files'));

var redis = require('redis').createClient(6379, 'redis');

var server = app.listen(80, function () {
    console.log('WEBUI running on port 80');
});

