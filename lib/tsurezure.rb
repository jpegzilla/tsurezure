#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'
require 'json'
require 'pry'

require_relative 'utils/http_utils' # mainly used to create http responses.
require_relative 'utils/object_utils' # various object  validation utilities
require_relative 'utils/error_codes' # for generating errors.
require_relative 'utils/response' # handles request and generates responses.

$TRZR_PROCESS_MODE = nil
$TRZR_LOG = true
TRZR_STARTED_AT = Time.now.to_i

ARGV.each do |arg|
  $TRZR_PROCESS_MODE = 'development' if arg == '--development'
  $TRZR_PROCESS_MODE = 'production' if arg == '--production'
  $TRZR_LOG = false if arg == '--silent'
end

$TRZR_PROCESS_MODE = 'production' if $TRZR_PROCESS_MODE.nil?

# main class for tsurezure.
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

      # to initialize: session and length of response
      responder = HTTPUtils::ServerResponse.new(
        @session,
        res[:message].bytesize
      )

      go_through_middleware request_object, responder, res, type
    end

    def get_correct_middleware(request_object)
      @middleware.keys.select do |pat|
        HTTPUtils::URLUtils.matches_url_regex(pat, request_object[:url]) ||
          pat == '*'
      end
    end

    def fix_req(request, mid)
      request[:vars] =
        HTTPUtils::URLUtils.get_match_indices(
          mid[:path_regex],
          request[:url]
        ) || {}

      request[:options] = mid[:options]

      request
    end

    def send_middleware_response(req, resp, type)
      res = resp.merge req

      responder = HTTPUtils::ServerResponse.new(
        @session,
        res[:message].bytesize
      )

      # pp res

      responder.respond res[:message], res[:options] || {}, res[:status], type
    end

    def call_each_middleware(request, middleware, type)
      alt = nil

      middleware.each do |path|
        break if alt

        @middleware[path]&.each do |mid|
          alt = mid[:callback].call fix_req(request, mid)
        end
      end

      return true unless alt

      send_middleware_response(request, alt, type)
    end

    def go_through_middleware(request_object, responder, res, type)
      exp = get_correct_middleware request_object

      done = call_each_middleware request_object, exp, type

      return unless done

      # to send: response, options, status, content_type
      responder.respond res[:message], res[:options] || {}, res[:status], type
    end

    ##
    # main process, allows server to handle requests
    def process(client, endpoints, middleware)
      @endpoints = endpoints
      @middleware = middleware
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
    @middleware = {}
  end

  attr_reader :endpoints # access endpoints object from outside scope

  def add_middleware(path, callback, options)
    unless path.is_a? String
      raise ArgumentError, 'first argument to middleware\
      must be string or function.'
    end

    middleware_object = {
      options: options, callback: callback, path_regex: path
    }

    @middleware[path] << middleware_object if @middleware[path]

    @middleware[path] = [middleware_object] unless @middleware[path]
  end

  def register(http_method, path, callback, options = nil)
    http_method = http_method.upcase
    insurance = ensure_registration http_method, path, callback, options

    raise ArgumentError, insurance if insurance.class == String

    # register a new endpoint but do not register dupes
    @endpoints[http_method] = {} unless @endpoints.key? http_method

    new_endpoint = { path: path, responder: callback, options: options }

    add_new_endpoint new_endpoint, http_method
  end

  ##
  # run when the server is prepared to accept requests.
  def listen(callback = nil)
    if $TRZR_PROCESS_MODE == 'development'
      puts "[trzr_dev] running on port #{@port}!"
    end

    # call the callback if there's one provided
    callback.call server_opts if callback.is_a? Proc

    # create a new thread for handle each incoming request
    loop do
      Thread.start(@server.accept) do |client|
        RequestHandler.new(client).process client, @endpoints, @middleware
      end
    end
  end

  def kill
    abort
  end

  private

  def server_opts
    {
      port: @port,
      endpoints: @endpoints,
      middleware: @middleware
    }
  end

  # ----------------------------------------
  # :section: registration of endpoints and
  # all endpoint management methods follow.
  # ----------------------------------------

  def ensure_registration(*args)
    verification = verify_registration(*args)

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

    valid_opts = %w[content_type method location]

    opts_valid = OUtil.check_against_array(options.keys, valid_opts, 'register')

    return 'invalid options provided to register.' unless opts_valid

    true # to ensure_registration
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
end

at_exit do
  if $TRZR_PROCESS_MODE == 'development' && $TRZR_LOG.true?
    time = Time.now.to_i - TRZR_STARTED_AT
    puts
    puts '[trzr_dev] shutting down. goodbye...'
    puts "[trzr_dev] shut down after #{Time.at(time).utc.strftime('%H:%M:%S')}."
    puts
  end
end
