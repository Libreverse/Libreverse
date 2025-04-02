# Security Configuration
# This file contains all security-related configurations including:
# - Content Security Policy
# - Secure Headers
# - Permissions Policy
# - CORS
# - Rate Limiting (Rack::Attack)
# - XMLRPC Security

# ===== Content Security Policy =====
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https

    # Use nonces instead of unsafe-inline for scripts and styles
    # Rails doesn't support :nonce as a source directly
    policy.script_src :self, :https
    policy.style_src :self, :https
    # The nonce will be applied automatically via the nonce generator below

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"

    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}") if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Hash for Turbo's progress bar style to allow it
    policy.style_src :self, :https, "'sha256-WAyOw4V+FqDc35lQPyRADLBWbuNK8ahvYEaQIYF1+Ps='"
    # Allow @vite/client to hot reload style changes in development
    policy.style_src(*policy.style_src, :unsafe_inline) if Rails.env.development?

    # If you're using WebSockets or similar:
    policy.connect_src :self, :https, "wss://*.libreverse.dev", "wss://*.geor.me"
    # Allow @vite/client to hot reload changes in development
    policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}") if Rails.env.development?
  end

  # Generate secure random nonces for permitted scripts and styles
  # Use a cryptographically strong random value instead of session ID
  config.content_security_policy_nonce_generator = ->(_) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Enforce the policy, do not just report
  config.content_security_policy_report_only = false
end

# ===== Additional Secure Headers =====
Rails.application.config.action_dispatch.default_headers.merge!(
  # Enable HTTP Strict Transport Security
  "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",

  # Prevent MIME type sniffing
  "X-Content-Type-Options" => "nosniff",

  # Prevent clickjacking
  "X-Frame-Options" => "SAMEORIGIN",

  # Enable XSS protection in browsers
  "X-XSS-Protection" => "1; mode=block"
)

# ===== Permissions Policy =====
Rails.application.config.permissions_policy do |policy|
  # Restrict access to sensitive browser features
  policy.camera      :none
  policy.microphone  :none
  policy.geolocation :none
  policy.usb         :none
  policy.payment     :none
  policy.gyroscope   :none
  policy.accelerometer :none
  policy.magnetometer :none
  policy.midi :none
  policy.display_capture :none
  policy.autoplay    :none

  # Allow features that might be needed
  policy.fullscreen  :self
  policy.screen_wake_lock :self
end

# ===== CORS Configuration =====
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Only allow specific origins
    origins "libreverse.geor.me", "libreverse.dev", "localhost:3000"

    # Only allow specific resources and methods
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end

# ===== Rate Limiting =====
module Rack
  class Attack
    # Global rate limiting for all requests
    throttle("req/ip", limit: 300, period: 5.minutes) do |req|
      req.ip unless req.path.start_with?("/assets")
    end

    # Set up response handling
    self.throttled_responder = lambda do |_env|
      [
        429,
        { "Content-Type" => "text/xml" },
        [ Api::XmlrpcController.new.fault_response(429, "Rate limit exceeded") ]
      ]
    end
  end
end

# ===== XMLRPC Security =====
Rails.application.config.after_initialize do
  # Configure XML-RPC security settings
  if defined?(XMLRPC)
    begin
      # Configure XML parser security
      # Remove less secure parsers if available
      if defined?(XMLRPC::XMLParser)
        secure_parsers = {}

        # Only use secure parsers like libxml if available
        secure_parsers["libxml"] = XMLRPC::XMLParser::LibXMLParser if XMLRPC::XMLParser.const_defined?(:LibXMLParser)

        # If no secure parsers are available, use default but with caution
        secure_parsers["rex_stream"] = XMLRPC::XMLParser::REXMLStreamParser if secure_parsers.empty? && XMLRPC::XMLParser.const_defined?(:REXMLStreamParser)

        # Set available parsers to only our secure list
        unless secure_parsers.empty?
          XMLRPC::XMLParser.each_installed_parser do |name|
              XMLRPC::XMLParser.remove_parser(name)
          rescue StandardError
              nil
          end

          secure_parsers.each do |name, parser|
            XMLRPC::XMLParser.add_parser(name, parser)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to configure XMLRPC security: #{e.message}")
    end

    # Limit request size to prevent DoS attacks (8 MB)
    Rails.application.config.action_dispatch.request_size_limit = 8.megabytes
  end
end

# ===== XMLRPC Blocks =====
Rails.application.config.middleware.insert_before 0, Rack::Runtime do
  use Rack::Protection::XSSHeader
  use Rack::Protection::ContentSecurityPolicy, frame_options: "DENY"

  # Validate content types for XML-RPC API
  use Rack::Protection::Base do |env|
    if env["PATH_INFO"] == "/api/xmlrpc" && env["REQUEST_METHOD"] == "POST"
      content_type = env["CONTENT_TYPE"]
      # Only allow multipart/form-data for XML-RPC requests
      !content_type&.include?("multipart/form-data")
    else
      false
    end
  end
end
