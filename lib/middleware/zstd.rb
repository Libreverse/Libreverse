# frozen_string_literal: true

require "rack"
require "zstandard"

module Rack
  # Rack middleware to compress HTTP responses using Zstandard.
  #
  # Options:
  #   :level - Integer compression level (optional)
  #   :sync  - Unused, provided for API consistency with other compression middlewares
  class Zstd
    def initialize(app, options = {})
      @app   = app
      @level = options[:level]
      @sync  = options[:sync]
    end

    def call(env)
      status, headers, response = @app.call(env)

      if compressible?(env, headers)
        # Aggregate body
        body = +""
        response.each { |chunk| body << chunk }

        compressed = compress(body)

        # Update headers
        headers["Content-Encoding"] = "zstd"
        headers["Content-Length"]   = compressed.bytesize.to_s

        # Ensure Vary header includes Accept-Encoding
        vary = headers["Vary"].to_s.split(",").map(&:strip)
        vary << "Accept-Encoding" unless vary.include?("Accept-Encoding")
        headers["Vary"] = vary.join(", ")

        [status, headers, [compressed]]
      else
        [status, headers, response]
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
      @level ? Zstandard.deflate(string, @level) : Zstandard.deflate(string)
    end
  end
end 