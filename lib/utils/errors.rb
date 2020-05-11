# frozen_string_literal: true

# simple methods for showing error messages
module ErrorMessage
  def self.invalid_key_error(method, key)
    raise ArgumentError, {
      message: "invalid key '#{key}' used as parameter to #{method}."
    }.to_json
  end

  def self.invalid_http_method_error(key, val, method)
    raise ArgumentError, {
      message: "#{key} used to access #{method}. use #{val}.",
      status: 405,
      options: {
        allowed: val
      }
    }.to_json
  end

  def self.missing_arguments_error(method)
    raise ArgumentError, {
      status: 500,
      message: "missing arguments to #{method}"
    }.to_json
  end

  def self.missing_parameter_error(method)
    raise ArgumentError, {
      status: 400,
      message: "missing url parameter id to #{method}."
    }.to_json
  end

  def self.invalid_structure_error(method, keys)
    raise ArgumentError, {
      status: 400,
      message: "invalid object with keys #{keys} passed to #{method}."
    }.to_json
  end

  def self.make_http_error(status, message, options)
    error = { status: status, options: options }
    error.delete :options if options.nil?

    case status.to_s.chr.to_i
    when 4
      error[:message] = "bad request: #{message}"
    when 5
      error[:message] = "server error: #{message}"
    end

    error.to_json
  end
end

# module for multiple custom error classes
module CustomError
  # for throwing a server error (like 500)
  class ServerError < StandardError
    def initialize(message = 'an internal server error occurred.')
      super
    end
  end
end
