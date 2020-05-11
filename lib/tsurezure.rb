#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'
require 'json'

require_relative 'utils/http_utils'
require_relative 'utils/object_utils'
require_relative 'utils/error_codes'
require_relative 'utils/response'

$PROCESS_MODE = nil
$LOG = true

ARGV.each do |arg|
  $PROCESS_MODE = 'development' if arg == '--development'
  $PROCESS_MODE = 'production' if arg == '--production'
  LOG = false if arg == '--silent'
end

$PROCESS_MODE = 'production' if $PROCESS_MODE.nil?

# for initializing a simple http server.
class Tsurezure
  include OUtil
  ##
  # this class is made to handle requests coming from
  # a single client on a tcp server.
  class RequestHandler
    include HTTPUtils
    include ErrorCodes
    include TResponse

    ##
    # initializes with a client socket returned from a +TCPSocket+ object.

    def initialize(session)
      @session = session
      # endpoints are organized into arrays, sorted by method.
      # ex: { get: [ ...endpoint objects ], post: [ ... ] }
      # etc.
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

      generate_response request_object
    end

    def generate_response(request_object)
      response = TResponse.get_response request_object, @endpoints

      # Logbook::Dev.log response, true, 'response from TResponse'

      # responder = HTTPUtils::ServerResponse(@session, response[:length])
    end

    # main process, allows server to handle requests
    def process(client)
      @request = client.gets
      # wait until server isn't recieving anything
      return if @session.gets.nil?
      return if @session.gets.chop.length.zero?

      request_made = HTTPUtils.make_proper_request client, @request

      request_to_handle = HTTPUtils.make_request_object request_made

      handle_request request_to_handle
    end
  end

  def initialize(port)
    raise ErrorCodes.nan_error 'port' unless port.is_a? Numeric
    raise ErrorCodes.range_error 0, 65_535 unless (0..65_535).include? port

    @server = TCPServer.new port
    @port = port
    @endpoints = {}
  end

  attr_reader :endpoints

  def listen
    puts "running on port #{@port}!"
    # create a new thread for handle each incoming request
    loop do
      Thread.start(@server.accept) do |client|
        RequestHandler.new(client).process client
      end
    end
  end

  def ensure_registration(*args)
    verification = verify_registration(*args)
    # pp verification
    return verification unless verification

    verification
  end

  def validate_registration_params(method, path, responder)
    unless TResponse::Utils.new.valid_methods.include? method
      return "#{method} is not a valid http method."
    end

    return 'invalid path type. must be a string.' unless path.class == String

    if path.empty? || path.chr != '/'
      return 'invalid path. must begin with "/".'
    end

    return 'invalid responder type. must a proc.' unless responder.class == Proc

    true
  end

  def verify_registration(http_method, path, responder, options)
    valid = validate_registration_params http_method, path, responder

    return valid unless valid == true
    return true if options.nil? || options.empty?
    return 'invalid options type.' unless options.class == Hash

    valid_opts = %w[imply_get]

    opts_valid = OUtil.check_object_keys(options.keys, valid_opts, 'register')

    return 'invalid options provided to register.' unless opts_valid

    true
  end

  def register(http_method, path, responder, options = nil)
    insurance = ensure_registration http_method.upcase, path, responder, options

    raise ArgumentError, insurance if insurance.class == String

    # register a new endpoint
    @endpoints[http_method] = [] unless @endpoints.key? http_method

    new_endpoint = { path: path, responder: responder, options: options }

    add_new_endpoint new_endpoint, http_method
  end

  def add_new_endpoint(endpoint, method)
    @endpoints[method].each do |item|
      if item[:path] == endpoint[:path]
        raise ArgumentError, 'cannot register duplicate path.'
      end
    end

    @endpoints[method] << endpoint
  end

  def kill
    abort
  end
end

at_exit { puts 'shutting down. goodbye...' }
