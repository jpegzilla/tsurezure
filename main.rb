# frozen_string_literal: true

require_relative 'lib/tsurezure'

server = Tsurezure.new(8888)

server.register 'get', '/', proc { |req|
  pp req
  { status: 200, message: { hello: 'world' }.to_json }
}, content_type: 'application/json'

server.register 'get', '/hello', proc { |_req = nil|
  { status: 404, message: 'hello stinky' }
}, content_type: 'text/plain'

server.listen
