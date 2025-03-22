# Secure XML-RPC configuration
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

    # Set cookies serializer to JSON to prevent possible code execution
    Rails.application.config.action_dispatch.cookies_serializer = :json

    # Limit request size to prevent DoS attacks (8 MB)
    Rails.application.config.action_dispatch.request_size_limit = 8.megabytes
  end
end
