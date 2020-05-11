# frozen_string_literal: true

require_relative 'errors'

# module for validating object structure, keys etc.
module OUtil
  include ErrorMessage
  # check url params to make sure they're not empty
  # on methods that require them
  def self.check_params(params, method)
    return unless params.nil? || params.empty?

    raise ErrorMessage.missing_parameter_error(method)
  end

  # make sure a key is the correct value
  def self.check_key(key, value, method)
    return if key == value

    raise ErrorMessage.invalid_key_error(method, key)
  end

  def self.check_http_method(key, value, method)
    return if key == value

    raise ErrorMessage.invalid_http_method_error(key, value, method)
  end

  def check_key_type(object, key, type, method)
    return if object[key].is_a? type

    raise ErrorMessage.invalid_key_error(method, key)
  end

  def self.check_object_keys(keys, valid_keys, method)
    key_bank = []

    keys.each do |key|
      break unless valid_keys.keys.include? key.to_sym
      break unless key.is_a? valid_keys[key.to_sym]

      key_bank.push key
    end

    return if key_bank.length == valid_keys.length

    raise ErrorMessage.invalid_structure_error(method, "(#{keys.join(', ')})")
  end
end
