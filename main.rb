# frozen_string_literal: true

require_relative 'lib/tsurezure'

$PROCESS_MODE = nil

ARGV.each do |arg|
  $PROCESS_MODE = 'development' if arg == '--development'
  $PROCESS_MODE = 'production' if arg == '--production'
end

server = Tsurezure::HTTPServer.new(8888)

server.listen
