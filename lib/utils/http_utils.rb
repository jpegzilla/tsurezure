# frozen_string_literal: true

require_relative 'logbook'

# all utilities for dealing with http-related things
module HTTPUtils
  include Logbook
  # class URLUtils - for dealing with urls
  class URLUtils
    def self.extract_url_params(url)
      url_params = []

      if url.split('?')[1]

        url_params = url.split('?')[1].split('&').map do |e|
          key, value = e.split('=')

          break if value.nil?

          { key: key, value: value }
        end
      end

      url_params
    end

    def self.get_match_indices(url, regex)
      matches = url.scan %r{((?<=\/):[^\/]+)}
      newstring = url.dup.gsub(%r{((?<=\/):[^\/]+)}, ':')

      res = []
      hash_with_variables = {}

      return if matches.empty? || url == '*'

      newstring.scan(matches[0][0][0]) do |chr|
        res << [chr, $LAST_MATCH_INFO.offset(0)[0]][1]
      end

      matches.each_with_index do |itm, idx|
        hash_with_variables[itm[0].gsub(':', '')] = regex[res[idx]]
      end

      hash_with_variables
    end

    def self.matches_url_regex(url, regex)
      matches = url.scan %r{((?<=\/):[^\/]+)}
      newregexp = url.dup

      return url.match? Regexp.new("^#{regex}$") if matches.empty?

      matches.each do |mat|
        newregexp.gsub!(Regexp.new(mat[0].to_s), '.+')
      end

      url.match? Regexp.new(newregexp)
    end
  end

  # for dealing with header data.
  class HeaderUtils
    def self.get_headers(client)
      headers = {}

      while (line = client.gets.split(' ', 2))
        break if line[0] == ''

        headers[line[0].chop] = line[1].strip
      end

      headers
    end

    def self.get_req_data(client, headers)
      data = client.read headers['Content-Length'].to_i

      return if data.empty?

      data
    end
  end

  def self.make_proper_request(client, request)
    headers = HeaderUtils.get_headers(client)
    data = HeaderUtils.get_req_data(client, headers)
    method = request.split(' ')[0]
    url = request.split(' ')[1]
    proto = request.split(' ')[2]

    { headers: headers, data: data, method: method, url: url, protocol: proto }
  end

  def self.make_request_object(req)
    req[:data] = '{}' if req[:data].nil?

    {
      headers: req[:headers],
      data: JSON.parse(req[:data]),
      method: req[:method],
      url: req[:url],
      protocol: req[:protocol]
    }
  end

  # class ServerResponses - for sending HTTP responses
  class ServerResponse
    def initialize(session, length)
      @session = session
      @length = length
    end

    def respond(response,
                options = {},
                status = 200,
                content_type = 'application/json')
      @content_type = options[:content_type] || content_type

      if respond_to? "r_#{status}"
        method("r_#{status}").call if options[:method].nil?
        method("r_#{status}").call options unless options[:method].nil?
      else
        r_400
      end

      @session.puts
      @session.puts response
      @session.close
    end

    def r_200
      @session.puts 'HTTP/1.1 200 OK'
      @session.puts "Content-Type: #{@content_type}"
      @session.puts "Content-Length: #{@length}"
    end

    def r_400
      @session.puts 'HTTP/1.1 400 Bad Request'
      @session.puts "Content-Type: #{@content_type}"
      @session.puts "Content-Length: #{@length}"
    end

    def r_404
      @session.puts 'HTTP/1.1 404 Not Found'
      @session.puts "Content-Type: #{@content_type}"
      @session.puts "Content-Length: #{@length}"
    end

    def r_405(options)
      @session.puts 'HTTP/1.1 405 Method Not Allowed'
      @session.puts "Content-Type: #{@content_type}"
      @session.puts "Content-Length: #{@length}"
      @session.puts "Allow: #{options['allowed']}"
    end

    def r_500
      @session.puts 'HTTP/1.1 500 Internal Server Error'
      @session.puts "Content-Type: #{@content_type}"
      @session.puts "Content-Length: #{@length}"
    end
  end
end

__END__

this is the file that made me realize that the content_length header actually directly controls the length of the content in the response. I incorrectly set the content_length once as a mistake, and my responses were coming out short. interesting!
