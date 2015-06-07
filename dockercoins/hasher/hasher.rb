require 'digest'
require 'sinatra'
require 'socket'

set :bind, '0.0.0.0'
set :port, 80

post '/' do
    content_type 'text/plain'
    "#{Digest::SHA2.new().update(request.body.read)}"
end

get '/' do
    "HASHER running on #{Socket.gethostname}\n"
end

