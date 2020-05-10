# frozen_string_literal: true

# for storing generic, reusable error codes.
module ErrorCodes
  def self.nan_error(item)
    "invalid parameter: #{item} must be a number."
  end

  def self.range_error(min, max)
    "invalid port number: port must be in range [#{min}, #{max}]"
  end
end
