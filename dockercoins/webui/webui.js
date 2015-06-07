var express = require('express');
var app = express();

app.get('/', function (req, res) {
    res.redirect('/index.html');
});

app.get('/json', function (req, res) {
    redis.lrange('timing', 0, -1, function (err, timing) {
        redis.hlen('wallet', function (err, coins) {
            timing.reverse();
            var speed10 = '?';
            var speed100 = '?';
            var speed1000 = '?';
            if (timing.length >= 10) {
                speed10 = 10 / (timing[0]-timing[9]);
            }
            if (timing.length >= 100) {
                speed100 = 100 / (timing[0]-timing[99]);
            }
            if (timing.length >= 1000) {
                speed1000 = 1000 / (timing[0]-timing[999]);
            }
            var now = Date.now() / 1000;
            res.json( {
                speed10: speed10,
                speed100: speed100,
                speed1000: speed1000,
                coins: coins,
                now: now,
                ago: now - timing[0]
            });
        });
    });
});

app.use(express.static('files'));

var redis = require('redis').createClient(6379, 'redis');

var server = app.listen(80, function () {
    console.log('WEBUI running on port 80');
});

