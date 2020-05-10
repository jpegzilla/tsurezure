# frozen_string_literal: true

# module for logging things
module Logbook
  # dev mode logging
  class Dev
    def self.log_json(data, break_around = true, tag = 'info')
      return unless $PROCESS_MODE == 'development'

      if break_around
        puts "\r\n#{tag} - #{caller.first}".black.bg_green
        puts JSON.pretty_generate data
        puts
      else
        puts "#{tag}\r\n#{caller.first}"
        pp data
      end
    end

    def self.log(data, break_around = true, tag = 'info')
      return unless $PROCESS_MODE == 'development'

      if break_around
        puts "\r\n#{tag} - #{caller.first}".black.bg_green
        pp data
        puts
      else
        puts "#{tag}\r\n#{caller.first}"
        pp data
      end
    end
  end
end

# some slight mods to the string class to allow colorization
class String
  def green
    "\e[32m#{self}\e[0m"
  end

  def blue
    "\e[34m#{self}\e[0m"
  end

  def black
    "\e[30m#{self}\e[0m"
  end

  def bg_red
    "\e[41m#{self}\e[0m"
  end

  def bg_green
    "\e[42m#{self}\e[0m"
  end
end
