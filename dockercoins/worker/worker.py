import http.client
import logging
import os
from redis import Redis
import time

DEBUG = os.environ.get("DEBUG", "").lower().startswith("y")

log = logging.getLogger(__name__)
level = logging.DEBUG if DEBUG else logging.INFO
logging.basicConfig(level=level)


redis = Redis("redis")


def get_random_bytes():
    log.debug("Connecting to RNG")
    connection = http.client.HTTPConnection("rng")
    log.debug("Sending request")
    connection.request("GET", "/4")
    response = connection.getresponse()
    random_bytes = response.read()
    log.debug("Got {} bytes of random data".format(len(random_bytes)))
    return random_bytes


def hash_bytes(data):
    log.debug("Connecting to HASHER")
    connection = http.client.HTTPConnection("hasher")
    log.debug("Sending request")
    connection.request(
        "POST", "/", data, {"Content-Type": "application/octet-stream"})
    response = connection.getresponse()
    hex_hash = response.read()
    log.debug("Got hash: {}...".format(hex_hash[:8]))
    return hex_hash


def work_once():
    log.debug("Doing one unit of work")
    random_bytes = get_random_bytes()
    hex_hash = hash_bytes(random_bytes)
    if not hex_hash.startswith(b'0'):
        log.debug("No coin found")
        return
    log.info("Coin found: {}...".format(hex_hash[:8]))
    created = redis.hset("wallet", hex_hash, random_bytes)
    if not created:
        log.info("We already had that coin")
        return
    log.debug("Storing timing information")
    now = time.time()
    redis.rpush("timing", now)
    redis.ltrim("timing", -1000, -1)
    log.debug("Getting timing information")
    oldest = float(redis.lrange("timing", 0, 0)[0])
    total = redis.llen("timing")
    if oldest == now:
        log.debug("oldest == now, can't compute timing")
        return
    speed = total / (now - oldest)
    log.info("Speed over the last {} coins: {} coins/s".format(total, speed))


if __name__ == "__main__":
    while True:
        work_once()



