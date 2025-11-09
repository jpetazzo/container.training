import express from 'express';
import morgan from 'morgan';
import { createClient } from 'redis';

var client = await createClient({
  url: "redis://redis",
  socket: {
    family: 0
  }
})
    .on("error", function (err) {
        console.error("Redis error", err);
    })
    .connect();

var app = express();

app.use(morgan('common'));

app.get('/', function (req, res) {
    res.redirect('/index.html');
});

app.get('/json', async(req, res) => {
    var coins = await client.hLen('wallet');
    var hashes = await client.get('hashes');
    var now = Date.now() / 1000;
    res.json({
        coins: coins,
        hashes: hashes,
        now: now
    });
});

app.use(express.static('files'));

var server = app.listen(80, function () {
    console.log('WEBUI running on port 80');
});

