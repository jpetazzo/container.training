from flask import Flask, Response
from prometheus_flask_exporter import PrometheusMetrics
import os
import socket
import time
import yaml

# Load configuration from YAML file if it exists, otherwise use defaults
default_config = {
    'port': 80,
    'sleep_duration': 0.1
}

if os.path.exists('config.yml'):
    with open('config.yml', 'r') as file:
        config = yaml.safe_load(file)
else:
    config = default_config

# Get configurations with precedence: ENV > YAML > default
port = int(os.environ.get("PORT", config.get('port', default_config['port'])))
sleep_duration = float(os.environ.get("SLEEP_DURATION", config.get('sleep_duration', default_config['sleep_duration'])))

app = Flask(__name__)

# Enable Prometheus metrics
metrics = PrometheusMetrics(app)

# Enable debugging if the DEBUG environment variable is set and starts with Y
app.debug = os.environ.get("DEBUG", "").lower().startswith('y')

hostname = socket.gethostname()
urandom = os.open("/dev/urandom", os.O_RDONLY)

@app.route("/")
def index():
    time.sleep(sleep_duration)  # Simulate processing time
    return f"RNG running on {hostname}\n"

@app.route("/<int:how_many_bytes>")
def rng(how_many_bytes):
    time.sleep(sleep_duration)  # Simulate processing time
    return Response(
        os.read(urandom, how_many_bytes),
        content_type="application/octet-stream"
    )

# Prometheus metrics will be exposed automatically on the /metrics endpoint
# The default metrics will include:
# 1. `flask_http_requests_total`: Total number of HTTP requests
# 2. `flask_http_request_duration_seconds`: Duration of HTTP requests

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port, threaded=False)
