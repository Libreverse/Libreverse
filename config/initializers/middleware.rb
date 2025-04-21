# frozen_string_literal: true

# Ensure custom middleware constant is loaded before we reference it below
require Rails.root.join("lib/ip_anonymizer")

# Middleware Configuration
# This file sets up the middleware stack for the application
# Including compression, HTML optimization, rate limiting, and emoji processing

# ===== Compression Middleware =====
# Compression is now simplified to avoid Safari 'cannot decode raw data' errors caused by
# double-compression. We only use Rack::Brotli in production – it will fall back to gzip
# automatically when the client doesn't advertise `br`.

# ===== HTML Optimization =====
# This option set is from the default readme of htmlcompressor
Rails.application.config.middleware.use HtmlCompressor::Rack,
                                        enabled: true,
                                        remove_spaces_inside_tags: true,
                                        remove_multi_spaces: true,
                                        remove_comments: true,
                                        remove_intertag_spaces: false,
                                        remove_quotes: false,
                                        compress_css: false,
                                        compress_javascript: false,
                                        simple_doctype: false,
                                        remove_script_attributes: false,
                                        remove_style_attributes: false,
                                        remove_link_attributes: false,
                                        remove_form_attributes: false,
                                        remove_input_attributes: false,
                                        remove_javascript_protocol: false,
                                        remove_http_protocol: false,
                                        remove_https_protocol: false,
                                        preserve_line_breaks: false,
                                        simple_boolean_attributes: false,
                                        compress_js_templates: false

# ===== Emoji Processing (Middleware for HTTP Requests) =====
# We insert the emoji middleware here so that it precedes
# the html minifier but still avoids unnecessary work

# ===== Rate Limiting =====
# Ensure Rack::Attack runs *before* compression so we don't waste CPU.
# Note: we insert it before Rack::Deflater programmatically below.

# ===== Maximum Body Size =====
# Block requests larger than 8 MiB to mitigate abuse when no reverse proxy
# is present. Responds with 413.
module Rack
  class MaximumBodySize
  def initialize(app, limit_bytes)
    @app = app
    @limit = limit_bytes
  end

  def call(env)
    length = env["CONTENT_LENGTH"].to_i
    return [ 413, { "Content-Type" => "text/plain" }, [ "Payload Too Large" ] ] if length > @limit && @limit.positive?

    @app.call(env)
  end
  end
end

# Insert body-size guard at the very top of stack
Rails.application.config.middleware.insert_before 0, Rack::MaximumBodySize, 8.megabytes

module Rack
  class Attack
    # Use Rails.cache for production
    Rack::Attack.cache.store = Rails.cache

    # Different limits for authenticated vs. unauthenticated users
    throttle("authenticated_req/ip", limit: 600, period: 1.minute) do |req|
      req.ip if req.env["rodauth"]&.logged_in?
    end

    throttle("unauthenticated_req/ip", limit: 300, period: 1.minute, &:ip)

    # Burst protection: Allow for some bursts but maintain long-term rate
    throttle("burst/ip", limit: 100, period: 10.seconds, &:ip)

    # Login throttling to prevent brute force attacks
    # Count login attempts by username and IP
    throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
      req.ip if req.path == "/login" && req.post?
    end

    throttle("logins/username", limit: 5, period: 5.minutes) do |req|
      if req.path == "/login" && req.post?
        # Extract username from the login form - better sanitized
        username = req.params["username"].to_s.downcase.gsub(/[^a-z0-9_-]/i, "")
        username.presence # Return nil if blank which won't be throttled
      end
    end

    # Throttle account creation
    throttle("account_creation/ip", limit: 3, period: 1.hour) do |req|
      req.ip if req.path == "/create-account" && req.post?
    end

    # Throttle password reset requests
    throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
      req.ip if req.path == "/reset-password" && req.post?
    end

    # Enhanced API protection:
    throttle("api/ip", limit: 60, period: 1.minute) do |req|
      req.path.start_with?("/api/") ? req.ip : nil
    end

    # Block repeated failed XML parsing attempts (potential DoS)
    throttle("api/xml/failed", limit: 5, period: 5.minutes) do |req|
      req.ip if req.path.start_with?("/api/") && req.env["xmlrpc.parse_failed"]
    end

    # Block suspicious scanning behavior
    blocklist("suspicious_behavior") do |req|
      Rack::Attack::Fail2Ban.filter("pentesters/#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
        # Block if SQL injection or XSS is detected in parameters
        req.params.values.any? do |value|
          value.to_s =~ /['"].*((select|union).*from|drop table|concat\(|javascript:|<script>|on\w+=)/i
        end
      end
    end

    # Custom responder with more nuanced messaging and retry information
    self.throttled_responder = lambda do |request|
      match_data = request.env["rack.attack.match_data"]
      now = Time.zone.now

      headers = {
        "Content-Type" => "application/json",
        "Retry-After" => (match_data[:period] - (now - match_data[:epoch])).to_i.to_s
      }

      [ 429, headers, [ {
        error: {
          message: "You've hit your request limit. Please try again in #{headers['Retry-After']} seconds.",
          limit: match_data[:limit],
          remaining: [ 0, match_data[:limit] - match_data[:count] ].max,
          reset_at: (now + match_data[:period] - (now - match_data[:epoch])).to_i
        }
      }.to_json ] ]
    end
  end
end

# Insert Rack::Attack cleanly:
middleware = Rails.application.config.middleware

begin
  middleware.insert_after Rack::MaximumBodySize, Rack::Attack
rescue ArgumentError
  # Rack::MaximumBodySize not present; prepend Rack::Attack
  middleware.insert_before 0, Rack::Attack
end

# Ensure IP anonymisation occurs after Rack::Attack (needs real IP)
middleware.insert_after Rack::Attack, IpAnonymizer

# Ensure Brotli compression runs *after* HTML minification
if Rails.env.production?
  middleware.insert_after HtmlCompressor::Rack, Rack::Brotli, {
    quality: 11,
    include: %w[text/html application/javascript text/css application/json application/xml],
    deflater: { lgwin: 22, lgblock: 0, mode: :text }, # mode: :text better for HTML/JS/CSS
    sync: false
  }
end
