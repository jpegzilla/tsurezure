# frozen_string_literal: true

require_relative './http_utils' # mainly used to create http responses.

VALID_METHODS = %w[
  CONNECT COPY DELETE GET HEAD
  LINK LOCK MKCOL MOVE OPTIONS
  PATCH POST PROPFIND PROPPATCH
  PURGE PUT TRACE UNLINK UNLOCK
  VIEW
].freeze

CHECK_METHOD_WARNING = "not found. \
please ensure you're using the right method!"

INVALID_METHOD_WARNING = 'an invalid method was used!'

##
# module for handling all incoming requests to the server
# stands for TsurezureResponse
module TResponse
  include HTTPUtils
  # anything that will be needed to create responses
  class Utils
    attr_reader :valid_methods

    def initialize
      @valid_methods = VALID_METHODS
    end

    def self.validate_request(request_params)
      # make sure the user has provided a valid http
      # method, a valid uri, and a valid response /
      # response type
      return true if VALID_METHODS.include? request_params[:method]

      Logbook::Dev.log(INVALID_METHOD_WARNING)
    end

    def self.get_correct_endpoint(request_object, endpoints)
      endpoints.keys.select do |pat|
        HTTPUtils::URLUtils.matches_url_regex?(pat, request_object[:url])
      end
    end

    def self.ensure_response(request, endpoints)
      return false if request.nil? || request.empty?
      return false if endpoints.nil? || endpoints.empty?

      endpoint = endpoints[get_correct_endpoint(request, endpoints)[0]]

      return false if endpoint.nil?

      true
    end
  end

  # creates the final response from the server
  def self.get_response(request, endpoints)
    Utils.validate_request request

    @endpoints = endpoints[request[:method]]

    # if no endpoint, respond with root endpoint or 404 middleware
    unless Utils.ensure_response(request, @endpoints) == true
      Logbook::Dev.log(CHECK_METHOD_WARNING)

      return { options: { content_type: 'application/json' },
               code: 22, status: 404,
               message: { status: 404, message: 'undefined endpoint' }.to_json }
    end

    endpoint = @endpoints[Utils.get_correct_endpoint(request, @endpoints)[0]]

    # find the correct endpoint to respond with
    activate_endpoint endpoint, request
  end

  def self.activate_endpoint(endpoint, request)
    final = endpoint.merge request
    final.delete :responder

    final[:vars] =
      HTTPUtils::URLUtils.get_match_indices(final[:path], final[:url])

    response_from_endpoint = endpoint[:responder].call final

    if response_from_endpoint.is_a? Hash
      response_from_endpoint[:options] = final[:options]
      return response_from_endpoint
    end

    { status: 200, message: response_from_endpoint }
  end
end
