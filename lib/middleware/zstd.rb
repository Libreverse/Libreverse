require "rack"
require "zstd-ruby"
require "digest/sha1"

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
      response = nil
      status, headers, response = @app.call(env)
      headers ||= {}

      # If the response is nil or not enumerable, return as-is (fixes NoMethodError in error cases)
      return [ status, headers, response ] unless response.respond_to?(:each)

      if compressible?(env, headers)
        # Aggregate body
        body = +""
        response.each { |chunk| body << chunk }

        # Cache compressed bytes based on original body and compression options
        opts = @options
        level_sig = opts.key?(:level) ? opts[:level].to_s : "nil"
        dict_sig  = if opts.key?(:dict)
                       # Avoid storing dict in key; use a hash of its content/identity
                       Digest::SHA1.hexdigest(opts[:dict].to_s)
        else
                       "nil"
        end
        cache_key = "zstd_body:#{Digest::SHA1.hexdigest(body)}:lvl:#{level_sig}:dict:#{dict_sig}"
        compressed = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          compress(body)
        end

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

    COMPRESSIBLE_CONTENT_TYPES = %w[
      text/html
      text/plain
      text/css
      text/javascript
      application/javascript
      application/json
      application/xml
      application/rss+xml
      application/atom+xml
      image/svg+xml
    ].map(&:downcase).map(&:freeze).freeze

    def compressible?(env, headers)
      return false if headers.nil?
      # Skip if already encoded
      return false if headers["Content-Encoding"]

      # Check Content-Type
      header_content_type = headers["Content-Type"]
      return false if header_content_type.blank?

      content_type = header_content_type.split(";").first.to_s.strip.downcase
      return false unless COMPRESSIBLE_CONTENT_TYPES.include?(content_type)

      # Check Accept-Encoding for zstd token, allowing for quality values (e.g. 'zstd;q=0.9')
      accept_enc = env["HTTP_ACCEPT_ENCODING"].to_s
      accept_enc.match?(/\bzstd\b/i)
    end

    def compress(string)
      # Only simple compression options supported by zstd-ruby (level and dict)
      opts = @options.dup
      compress_args = {}
      compress_args[:level] = opts.delete(:level) if opts.key?(:level)
      compress_args[:dict]  = opts.delete(:dict)  if opts.key?(:dict)
      ::Zstd.compress(string, **compress_args)
    end
  end
end
