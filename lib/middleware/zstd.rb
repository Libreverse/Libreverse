# frozen_string_literal: true

require "rack"
require "zstd-ruby"

module Rack
  # Rack middleware to compress HTTP responses using Zstandard.
  #
  # Options:
  #   :level - Integer compression level (optional)
  #   :sync  - Unused, provided for API consistency with other compression middlewares
  class Zstd
    # Use class instance var instead of class var for compression logging
    @logged_compression = false

    class << self
      attr_accessor :logged_compression
    end

    def initialize(app, options = {})
      @app = app
      # Store all compression options; :level will be remapped
      @options = options.dup
      @sync = @options.delete(:sync)
    end

    def call(env)
      status, headers, response = @app.call(env)

      if compressible?(env, headers)
        # Aggregate body
        body = +""
        response.each { |chunk| body << chunk }

        compressed = compress(body)

        # Log once when compression is used
        unless self.class.logged_compression
          Rails.logger.info("Rack::Zstd: response compressed with Zstandard")
          self.class.logged_compression = true
        end

        # Update headers
        headers["Content-Encoding"] = "zstd"
        headers["Content-Length"]   = compressed.bytesize.to_s

        # Ensure Vary header includes Accept-Encoding
        vary = headers["Vary"].to_s.split(",").map(&:strip)
        vary << "Accept-Encoding" unless vary.include?("Accept-Encoding")
        headers["Vary"] = vary.join(", ")

        [ status, headers, [ compressed ] ]
      else
        [ status, headers, response ]
      end
    ensure
      response.close if response.respond_to?(:close)
    end

    private

    def compressible?(env, headers)
      return false if headers["Content-Encoding"]

      accept_enc = env["HTTP_ACCEPT_ENCODING"].to_s
      accept_enc.split(/[
   ,]+/).include?("zstd")
    end

    def compress(string)
      # Use zstd-ruby gem for compression
      opts = @options.dup
      Zstd.compress(string, **opts)
    end
  end
end
