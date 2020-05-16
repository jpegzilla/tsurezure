# frozen_string_literal: true

##
# module for handling all incoming requests to the server
# stands for TsurezureResponse
module TResponse

  # anything that will be needed to create responses
  class Utils
    def initialize
      @valid_methods = %w[
        CONNECT COPY DELETE GET HEAD
        LINK LOCK MKCOL MOVE OPTIONS
        OPTIONS PATCH POST PROPFIND
        PROPPATCH PURGE PUT TRACE
        UNLINK UNLOCK VIEW
      ]
    end

    attr_reader :valid_methods

    def self.validate_request(request_params)
      # make sure the user has provided a valid http
      # method, a valid uri, and a valid response /
      # response type
      valid_methods = %w[
        CONNECT COPY DELETE GET HEAD
        LINK LOCK MKCOL MOVE OPTIONS
        OPTIONS PATCH POST PROPFIND
        PROPPATCH PURGE PUT TRACE
        UNLINK UNLOCK VIEW
      ]

      return false unless valid_methods.include? request_params[:method]
    end

    def self.ensure_response(request, endpoints)
      return false if request.nil? || request.empty?
      return false if endpoints.nil? || endpoints.empty?

      endpoint = endpoints[request[:method]][request[:url]]

      return false if endpoint.nil?

      true
    end
  end

  # creates the final response from the server
  def self.get_response(request, endpoints)
    Utils.validate_request request

    # Logbook::Dev.log request, true, 'request'

    unless Utils.ensure_response(request, endpoints) == true
      return { status: 404, message: 'undefined endpoint' }
    end

    endpoint = endpoints[request[:method]][request[:url]]
    # find the correct endpoint to respond with
    activate_endpoint endpoint, request
  end

  def self.activate_endpoint(endpoint, request)
    final = endpoint.merge request
    final.delete :responder

    response_from_endpoint = endpoint[:responder].call final

    unless response_from_endpoint.is_a? Hash
      return { status: 200, message: response_from_endpoint }
    end

    response_from_endpoint[:options] = final[:options]

    response_from_endpoint
  end
end
