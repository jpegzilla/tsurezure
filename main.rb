# frozen_string_literal: true

require_relative 'lib/tsurezure'

server = Tsurezure.new 8888

# ===================================================================

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
  # puts
  # pp 'hello from middleware one! request:'
  # puts req
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

server.add_middleware '/user/:id', lambda { |req|
  # pp req
  url_vars = req[:vars]

  if req[:vars]['id'] == '1'
    return { status: 200, message: { message:
      "hey user ##{url_vars['id']}! you're the first one here!" }.to_json }
  end
}, content_type: 'application/json'

# ===================================================================

server.register 'get', '/', lambda { |_req|
  { status: 200, message: { hello: 'world' }.to_json }
}, content_type: 'application/json'

server.register 'get', '/user/:id', lambda { |req|
  url_vars = req[:vars] # { "id" => "1" }
  params = req[:params] # {}

  { status: 200, message: { message:
    "hello user ##{url_vars['id']}!" }.to_json }
}, content_type: 'application/json'

server.listen
