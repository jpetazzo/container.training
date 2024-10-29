"use strict";

const express = require('express');
const redis = require('redis');
const YAML = require('yamljs');
const fs = require('fs');

const app = express();

// Load configuration from YAML file if it exists, otherwise use defaults
let config = {
    redis_host: 'redis',
    redis_port: 6379,
    listen_port: 80
};

if (fs.existsSync('config.yml')) {
    const yamlConfig = YAML.load('config.yml');
    config = Object.assign({}, config, yamlConfig);
}

// Environment variables override YAML settings
const REDIS_HOST = process.env.REDIS_HOST || config.redis_host;
const REDIS_PORT = parseInt(process.env.REDIS_PORT) || config.redis_port;
const LISTEN_PORT = parseInt(process.env.LISTEN_PORT) || config.listen_port;

// Initialize Redis client with configured host and port
const client = redis.createClient(REDIS_PORT, REDIS_HOST);
client.on("error", function (err) {
    console.error("Redis error", err);
});

app.get('/', function (req, res) {
    res.redirect('/index.html');
});

app.get('/json', function (req, res) {
    client.hlen('wallet', function (err, coins) {
        client.get('hashes', function (err, hashes) {
            const now = Date.now() / 1000;
            res.json({
                coins: coins,
                hashes: hashes,
                now: now
            });
        });
    });
});

app.use(express.static('files'));

// Start server with configured listen port
const server = app.listen(LISTEN_PORT, function () {
    console.log(`WEBUI running on port ${LISTEN_PORT}`);
});
