#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'
require 'json'
require 'pry'

require_relative 'utils/http_utils' # mainly used to create http responses.
require_relative 'utils/object_utils' # various object  validation utilities
require_relative 'utils/error_codes' # for generating errors.
require_relative 'utils/response' # handles request and generates responses.

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
    # constructs a formatted request object from the original request object,
    # and calls +send_final_response+ in order to send a response.
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

    ##
    # generate a response from a supplied request object
    # from +handle_request+.
    def generate_response(request_object)
      type = 'text/plain'

      unless request_object[:options].nil? || request_object[:options].empty?
        type = request_object[:options][:content_type]
      end

      res = TResponse.get_response request_object, @endpoints

      # Logbook::Dev.log response, true, 'response from TResponse'

      # to initialize: session and length of response
      responder = HTTPUtils::ServerResponse.new(
        @session,
        res[:message].bytesize
      )

      # to send: response, options, status, content_type
      responder.respond res[:message], res[:options], res[:status], type
    end

    ##
    # main process, allows server to handle requests
    def process(client, endpoints)
      @endpoints = endpoints
      @request = client.gets
      # wait until server isn't recieving anything
      return if @session.gets.nil?
      return if @session.gets.chop.length.zero?

      request_made = HTTPUtils.make_proper_request client, @request

      request_to_handle = HTTPUtils.make_request_object request_made

      handle_request request_to_handle
    end
  end

  ##
  # prepares the server to run on a specified port.
  def initialize(port)
    raise ErrorCodes.nan_error 'port' unless port.is_a? Numeric
    raise ErrorCodes.range_error 0, 65_535 unless (0..65_535).include? port

    @server = TCPServer.new port
    @port = port
    @endpoints = {}
  end

  attr_reader :endpoints # access endpoints object from outside scope

  ##
  # run when the server is prepared to accept requests.
  def listen
    puts "running on port #{@port}!"
    # create a new thread for handle each incoming request
    loop do
      Thread.start(@server.accept) do |client|
        RequestHandler.new(client).process client, @endpoints
      end
    end
  end

  # ----------------------------------------
  # :section: registration of endpoints and
  # all endpoint management methods follow.
  # ----------------------------------------

  def ensure_registration(*args)
    verification = verify_registration(*args)
    # pp verification
    return verification unless verification

    verification # to register
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

    valid_opts = %w[content_type]

    opts_valid = OUtil.check_against_array(options.keys, valid_opts, 'register')

    return 'invalid options provided to register.' unless opts_valid

    true # to ensure_registration
  end

  def register(http_method, path, responder, options = nil)
    http_method = http_method.upcase
    insurance = ensure_registration http_method, path, responder, options

    raise ArgumentError, insurance if insurance.class == String

    # register a new endpoint
    @endpoints[http_method] = {} unless @endpoints.key? http_method

    new_endpoint = { path: path, responder: responder, options: options }

    add_new_endpoint new_endpoint, http_method
  end

  def add_new_endpoint(endpoint, method)
    @endpoints[method].each do |_, value|
      if value[:path] == endpoint[:path]
        raise ArgumentError, 'cannot register duplicate path.'
      end
    end

    # add endpoint to list of registered endpoints
    @endpoints[method][endpoint[:path]] = endpoint
  end

  # ----------------------------------------
  # :section: middleware management methods
  # all middleware management methods follow.
  # ----------------------------------------

  # def middleware(path_regex, options, callback)
  #
  # end

  def kill
    abort
  end
end

at_exit { puts 'shutting down. goodbye...' }
