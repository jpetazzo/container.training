import logging
import os
from redis import Redis
import requests
import time
import yaml

# Load configuration from YAML file if it exists, otherwise use defaults
default_config = {
    'redis_host': 'redis',
    'redis_port': 6379,
    'hasher_host': 'hasher',
    'hasher_port': 80,
    'rng_host': 'rng',
    'rng_port': 80,
    'sleep_duration': 0.1
}

if os.path.exists('config.yml'):
    with open('config.yml', 'r') as file:
        config = yaml.safe_load(file)
else:
    config = default_config

# Environment variables override YAML settings
DEBUG = os.environ.get("DEBUG", "").lower().startswith("y")
REDIS_HOST = os.environ.get("REDIS_HOST", config.get('redis_host', default_config['redis_host']))
REDIS_PORT = int(os.environ.get("REDIS_PORT", config.get('redis_port', default_config['redis_port'])))
HASHER_HOST = os.environ.get("HASHER_HOST", config.get('hasher_host', default_config['hasher_host']))
HASHER_PORT = int(os.environ.get("HASHER_PORT", config.get('hasher_port', default_config['hasher_port'])))
RNG_HOST = os.environ.get("RNG_HOST", config.get('rng_host', default_config['rng_host']))
RNG_PORT = int(os.environ.get("RNG_PORT", config.get('rng_port', default_config['rng_port'])))
SLEEP_DURATION = float(os.environ.get("SLEEP_DURATION", config.get('sleep_duration', default_config['sleep_duration'])))

# Configure logging
log = logging.getLogger(__name__)
if DEBUG:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("requests").setLevel(logging.WARNING)

# Initialize Redis with configured host and port
redis = Redis(host=REDIS_HOST, port=REDIS_PORT)


def get_random_bytes():
    # Use RNG_HOST and RNG_PORT for the RNG service
    r = requests.get(f"http://{RNG_HOST}:{RNG_PORT}/32")
    return r.content


def hash_bytes(data):
    # Use HASHER_HOST and HASHER_PORT for the hasher service
    r = requests.post(f"http://{HASHER_HOST}:{HASHER_PORT}/", data=data, headers={"Content-Type": "application/octet-stream"})
    hex_hash = r.text
    return hex_hash


def work_loop(interval=1):
    deadline = 0
    loops_done = 0
    while True:
        if time.time() > deadline:
            log.info("{} units of work done, updating hash counter".format(loops_done))
            redis.incrby("hashes", loops_done)
            loops_done = 0
            deadline = time.time() + interval
        work_once()
        loops_done += 1


def work_once():
    log.debug("Doing one unit of work")
    time.sleep(SLEEP_DURATION)  # Use the configured sleep duration
    random_bytes = get_random_bytes()
    hex_hash = hash_bytes(random_bytes)
    if not hex_hash.startswith('0'):
        log.debug("No coin found")
        return
    log.info("Coin found: {}...".format(hex_hash[:8]))
    created = redis.hset("wallet", hex_hash, random_bytes)
    if not created:
        log.info("We already had that coin")


if __name__ == "__main__":
    while True:
        try:
            work_loop()
        except Exception:
            log.exception("In work loop:")
            log.error("Waiting 10s and restarting.")
            time.sleep(10)
