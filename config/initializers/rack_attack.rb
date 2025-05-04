# frozen_string_literal: true

# Ensure custom middleware constant is loaded before we reference it below
require Rails.root.join("lib/ip_anonymizer")
require "re2"

# Maximum Body Size Middleware Definition
# (Moved here from maximum_body_size.rb to resolve load order issues)
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

# Rack::Attack Rate Limiting Configuration
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
        username = req.params["username"].to_s.downcase.gsub(
          RE2::Regexp.new("[^a-z0-9_-]", case_sensitive: false),
          ""
        )
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
          RE2::Regexp.new("['\"].*((select|union).*from|drop table|concat\\(|javascript:|<script>|on\\\\w+=)", case_sensitive: false).match?(value.to_s)
        end
      end
    end

    # Custom JSON responder with retry information
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

# Only insert middleware if not in development environment
unless Rails.env.development?
  # Insert Rack::Attack middleware
  # Ensures it runs after Rack::MaximumBodySize (if present) but before others like compression.
  middleware = Rails.application.config.middleware

  # Insert MaximumBodySize first
  middleware.insert_before 0, Rack::MaximumBodySize, 2.gigabytes

  begin
    # Try inserting after MaximumBodySize for ideal placement
    middleware.insert_after Rack::MaximumBodySize, Rack::Attack
  rescue ArgumentError
    # Fallback: Insert near the top if MaximumBodySize isn't found
    middleware.insert_before 0, Rack::Attack
  end

  # Ensure IP anonymisation occurs after Rack::Attack (needs real IP)
  middleware.insert_after Rack::Attack, IpAnonymizer
end
