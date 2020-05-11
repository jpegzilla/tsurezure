# frozen_string_literal: true

require_relative 'lib/tsurezure'

server = Tsurezure.new(8888)

get_root = proc do |_req = nil, _res = nil|
  'hello world'
end

get_hello = proc do |_req = nil, _res = nil|
  'hello world'
end

# current registration options:
# imply_get for non-strict request methods,
# meaning that if you register an endpoint with x method,
# and someone accesses it by y method, you can allow that
# 'invalid' request to be treated as a get request

server.register 'get', '/', get_root
server.register 'get', '/hello', get_hello

server.listen
