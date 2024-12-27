# Strange as it may seem this is the order that gets the html minifier
# to run before the deflater and brotli because middlewares are,
# unintuitively, run as a stack from the bottom up.
Rails.application.config.middleware.use Rack::Deflater, include: %w[text/html], sync: false
Rails.application.config.middleware.use Rack::Brotli, quality: 11, include: %w[text/html], deflater: { lgwin: 22, lgblock: 0, mode: :text }, sync: false

# this option set is from the default readme of htmlcompressor
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

# We insert the emoji middleware here so that it precedes
# the html minifier but still avoids unnecessary work
Rails.application.config.middleware.use EmojiReplacer

# We make sure that rack-attack runs first so that we don't
# waste resources on compressing requests that will be throttled.
class Rack::Attack
  # Use Rails.cache for production
  Rack::Attack.cache.store = Rails.cache

  # Different limits for authenticated vs. unauthenticated users
  # throttle("authenticated_req/ip", limit: 1200, period: 1.minute) do |req|
  #   if req.env["warden"].user # Assuming you're using Devise or similar for authentication
  #     req.ip
  #   end
  # end

  throttle("unauthenticated_req/ip", limit: 300, period: 1.minute) do |req|
      # unless req.env["warden"].user
      req.ip
    # end
  end

  # Burst protection: Allow for some bursts but maintain long-term rate
  throttle("burst/ip", limit: 100, period: 10.seconds) do |req|
    req.ip
  end

  # Specific endpoint protection:
  # Example: Limit more for write operations or sensitive endpoints
  # throttle("write/ip", limit: 100, period: 1.minute) do |req|
  #   req.path.start_with?('/api/v1/write') ? req.ip : nil
  # end

  # Custom responder with more nuanced messaging and retry information
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = Time.now

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

Rails.application.config.middleware.use Rack::Attack
