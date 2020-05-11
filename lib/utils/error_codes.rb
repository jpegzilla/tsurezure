# frozen_string_literal: true

# for storing generic, reusable error codes.
module ErrorCodes
  def self.nan_error(item)
    "invalid parameter: #{item} must be a number."
  end

  def self.no_method_error(item)
    "invalid http method: #{item} is not a valid http method."
  end

  def self.invalid_type_error(item)
    "invalid type: #{item} is not a valid type."
  end

  def self.range_error(min, max)
    "invalid port number: port must be in range [#{min}, #{max}]"
  end

  def self.invalid_structure_error(keys, method)
    "invalid object with keys #{keys} supplied to #{method}"
  end
end
