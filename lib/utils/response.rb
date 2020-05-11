# frozen_string_literal: true

##
# module for handling all incoming requests to the server
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

      Logbook::Dev.log request_params, true, 'request_params'
    end

    def self.ensure_response(request, endpoints)
      return false if request.nil? || request.empty?
      return false if endpoints.empty?

      true
    end
  end

  # creates the final response from the server
  def self.get_response(request, endpoints)
    Utils.validate_request(request)

    # Logbook::Dev.log request, true, 'request'

    unless Utils.ensure_response(request, endpoints)
      { error: 404, message: 'no endpoint at' }
    end
    # find the correct endpoint to respond with

    # Logbook::Dev.log request, true, 'responding to request'
  end
end
