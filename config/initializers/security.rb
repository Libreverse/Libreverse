# frozen_string_literal: true

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
    policy.img_src     :self, :https, :data, :blob # Includes data: URIs for background images
    policy.object_src  :none

    # Base policies
    policy.script_src  :self, :https, :unsafe_inline, :data
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   :self, :data
    policy.connect_src :self, :https, "wss://*.libreverse.dev", "wss://*.geor.me", :data

    # Keep development-specific additions separately for clarity
    if Rails.env.development?
      policy.script_src(*policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}")
      policy.connect_src(*policy.connect_src, "ws://#{ViteRuby.config.host_with_port}")
    end

    # Keep test-specific additions
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Nonces are incompatible with dynamically generated srcdoc content.
    # 'unsafe-inline' is now relied upon for script-src and style-src.
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # --- Nonce Configuration DISABLED to allow srcdoc inline content ---
  # Nonces are incompatible with dynamically generated srcdoc content.
  # 'unsafe-inline' is now relied upon for script-src and style-src.
  # config.content_security_policy_nonce_generator = ->(_) { SecureRandom.base64(16) }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]
  # --- End Nonce Configuration ---

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

    # Helper to generate XML fault responses without instantiating a controller
    def self.generate_xml_fault_response(code, message)
      require "nokogiri"
      require "cgi"

      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.methodResponse do
          xml.fault do
            xml.value do
              xml.struct do
                xml.member do
                  xml.name("faultCode")
                  xml.value do
                    xml.int(code.to_s)
                  end
                end
                xml.member do
                  xml.name("faultString")
                  xml.value do
                    xml.string(CGI.escapeHTML(message))
                  end
                end
              end
            end
          end
        end
      end

      builder.to_xml
    end

    # Set up response handling
    self.throttled_responder = lambda do |_env|
      [
        429,
        { "Content-Type" => "text/xml" },
        [ generate_xml_fault_response(429, "Rate limit exceeded") ]
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
        if secure_parsers.empty? && XMLRPC::XMLParser.const_defined?(:REXMLStreamParser)
          secure_parsers["rex_stream"] =
            XMLRPC::XMLParser::REXMLStreamParser
        end

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
