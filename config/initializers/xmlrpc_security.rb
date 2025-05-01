# frozen_string_literal: true

# XMLRPC Security Configuration
Rails.application.config.after_initialize do
  if defined?(XMLRPC)
    begin
      if defined?(XMLRPC::XMLParser)
        secure_parsers = {}

        secure_parsers["libxml"] = XMLRPC::XMLParser::LibXMLParser if XMLRPC::XMLParser.const_defined?(:LibXMLParser)
        # Do not include REXML parser fallback; we rely solely on Nokogiri

        unless secure_parsers.empty?
          XMLRPC::XMLParser.each_installed_parser do |name|
              XMLRPC::XMLParser.remove_parser(name)
          rescue StandardError
              nil
          end
          secure_parsers.each { |name, parser| XMLRPC::XMLParser.add_parser(name, parser) }
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to configure XMLRPC security: #{e.message}")
    end

    # Prevent large POST bodies in XMLRPC
    Rails.application.config.action_dispatch.request_size_limit = 8.megabytes
  end
end

# XMLRPC Blocks Middleware
Rails.application.config.middleware.insert_before 0, Rack::Runtime do
  use Rack::Protection::XSSHeader
  use Rack::Protection::ContentSecurityPolicy, frame_options: "DENY"

  use Rack::Protection::Base do |env|
    if env["PATH_INFO"] == "/api/xmlrpc" && env["REQUEST_METHOD"] == "POST"
      !env["CONTENT_TYPE"]&.include?("multipart/form-data")
    else
      false
    end
  end
end
