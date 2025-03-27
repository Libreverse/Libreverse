# Middleware Configuration
# This file sets up the middleware stack for the application
# Including compression, HTML optimization, rate limiting, and emoji processing

# ===== Compression Middleware =====
# Strange as it may seem this is the order that gets the html minifier
# to run before the deflater and brotli because middlewares are,
# unintuitively, run as a stack from the bottom up.
Rails.application.config.middleware.use Rack::Deflater, include: %w[text/html], sync: false
Rails.application.config.middleware.use Rack::Brotli, quality: 11, include: %w[text/html], deflater: { lgwin: 22, lgblock: 0, mode: :text }, sync: false

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

# ===== Emoji Processing =====
# We insert the emoji middleware here so that it precedes
# the html minifier but still avoids unnecessary work
Rails.application.config.middleware.use EmojiReplacer, exclude_selectors: [
  "script", "style", "pre", "code", "textarea", "svg", "noscript", "template",
  ".no-emoji", "[data-no-emoji]", ".syntax-highlighted"
]

# ===== Rate Limiting =====
# We make sure that rack-attack runs first so that we don't
# waste resources on compressing requests that will be throttled.
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
        # Extract username from the login form
        req.params["username"].to_s.downcase.gsub(/\s+/, "")
      end
    end

    # Allow up to 15 password resets per day per IP
    throttle("password_reset/ip", limit: 15, period: 1.day) do |req|
      req.ip if req.path == "/reset-password" && req.post?
    end

    # Specific endpoint protection:
    throttle("api/ip", limit: 120, period: 1.minute) do |req|
      req.path.start_with?("/api/") ? req.ip : nil
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

Rails.application.config.middleware.use Rack::Attack
