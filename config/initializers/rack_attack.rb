# frozen_string_literal: true

# Rack::Attack Rate Limiting Configuration
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

    # Set up XMLRPC-specific response handling
    self.throttled_responder = lambda do |_env|
      [
        429,
        { "Content-Type" => "text/xml" },
        [ generate_xml_fault_response(429, "Rate limit exceeded") ]
      ]
    end
  end
end
