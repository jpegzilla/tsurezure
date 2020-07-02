# frozen_string_literal: true

require_relative 'lib/tsurezure'

server = Tsurezure.new 8888

# server.add_middleware '/', proc { |req|
#   # puts
#   # pp 'hello from middleware one! request:'
#   # puts req
# }, {}

server.add_middleware '*', lambda { |req|
  # puts
  # puts 'this affects ALL middleware. request:'
  # puts req
}, {}

server.add_middleware '/', lambda { |req|
  puts
  pp 'hello from middleware one! request:'
  puts req
}, {}

server.add_middleware '/user/:id/articles/:num', lambda { |req|
  # puts
  # pp 'hello from the ARTICLE MIDDLEWARE!'
  # puts req
}, {}

server.add_middleware '/e', lambda { |req|
  # puts
  # pp 'this middleware will affect MIDDLEWARE E'
  # puts req
}, {}

server.register 'get', '/', lambda { |_req = nil|
  { status: 200, message: { hello: 'world' }.to_json }
}, content_type: 'application/json'

server.register 'get', '/hello', lambda { |req|
  pp req
  { status: 404, message: 'hello stinky' }
}, content_type: 'text/plain'

server.register 'get', '/e', lambda { |_req = nil|
  { status: 404, message: { hello: 'e' }.to_json }
}, content_type: 'application/json'

server.register 'get', '/user/:id/articles/:num', lambda { |req|
  vars = req[:vars]

  { status: 404, message: { message:
    "hello user ##{vars['id']}, your article is ##{vars['num']}!" }.to_json }
}, content_type: 'application/json'

server.listen
