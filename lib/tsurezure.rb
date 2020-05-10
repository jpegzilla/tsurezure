# frozen_string_literal: true

require 'json'

require_relative 'utils/http_utils'
require_relative 'utils/error_codes'

$PROCESS_MODE = 'production' if $PROCESS_MODE.nil?

##
# this class is made to handle requests coming from
# a single client on a tcp server.
class RequestHandler
  include HTTPUtils
  include ErrorCodes

  ##
  # initializes with a client socket returned from a +TCPSocket+ object.

  def initialize(session)
    @session = session
  end

  ##
  # handles an incoming request from the open socket in +@session+.
  # constructs a formatted request object from the original request object, then
  # calls +send_final_response+ in order to send a response.
  def handle_request(request)
    url_main = request[:url].split('?')[0]

    request_object = {
      method: request[:method],
      url: url_main,
      params: HTTPUtils::URLUtils.extract_url_params(request[:url]),
      protocol: request[:protocol],
      headers: request[:headers],
      data: request[:data]
    }

    pp request_object
  end

  # main process, allows server to handle requests
  def process(client)
    @request = client.gets
    # wait until server isn't recieving anything
    return if @session.gets.nil?
    return if @session.gets.chop.length.zero?

    request_made = HTTPUtils.make_proper_request(client, @request)

    request_to_handle = HTTPUtils.make_request_object(request_made)

    handle_request(request_to_handle)
  end
end

module Tsurezure
  # for initializing a simple http server.
  class HTTPServer
    def initialize(port)
      raise ErrorCodes.nan_error 'port' unless port.is_a? Numeric
      raise ErrorCodes.range_error 0, 65_535 unless (0..65_535).include? port

      @server = TCPServer.new port
      @port = port
    end

    def listen
      puts "running on port #{@port}!"
      # create a new thread for handle each incoming request
      loop do
        Thread.start(@server.accept) do |client|
          RequestHandler.new(client).process(client)
        end
      end
    end

    def kill
      abort
    end
  end
end

at_exit { puts 'shutting down. goodbye...' }
