require 'digest'
require 'sinatra'
require 'socket'
require 'yaml'
require 'prometheus/client'
require 'prometheus/client/formats/text'  # Import the text formatter

# Define default configuration
default_config = {
  'port' => 80,
  'sleep_duration' => 0.1
}

# Load configuration from YAML file if it exists, otherwise use defaults
config = if File.exist?('config.yml')
           YAML.load_file('config.yml')
         else
           default_config
         end

# Set port with precedence: ENV > YAML > default (80)
set :port, (ENV['PORT'] || config['port'] || default_config['port']).to_i
set :bind, '0.0.0.0'

# Set sleep duration with precedence: ENV > YAML > default (0.1)
SLEEP_DURATION = (ENV['SLEEP_DURATION'] || config['sleep_duration'] || default_config['sleep_duration']).to_f

# Initialize Prometheus client
prometheus = Prometheus::Client.registry

# Create metrics
request_counter = prometheus.counter(:hash_requests_total, docstring: 'Total number of hash requests', labels: [:method])
request_duration = prometheus.histogram(:hash_request_duration_seconds, docstring: 'Duration of hash requests in seconds', labels: [:method])

post '/' do
  start_time = Time.now

  # Simulate a bit of delay using the configured sleep duration
  sleep SLEEP_DURATION
  content_type 'text/plain'
  hash_value = "#{Digest::SHA2.new.update(request.body.read)}"

  # Record metrics
  request_counter.increment(labels: { method: 'POST' })
  request_duration.observe(Time.now - start_time, labels: { method: 'POST' })

  hash_value
end

get '/' do
  start_time = Time.now

  sleep SLEEP_DURATION
  response = "HASHER running on #{Socket.gethostname}\n"

  # Record metrics
  request_counter.increment(labels: { method: 'GET' })
  request_duration.observe(Time.now - start_time, labels: { method: 'GET' })

  response
end

# Endpoint to expose metrics
get '/metrics' do
  content_type 'text/plain'
  # Use the Text formatter to convert metrics to the right format
  Prometheus::Client::Formats::Text.marshal(prometheus)
end
