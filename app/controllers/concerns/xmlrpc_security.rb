# frozen_string_literal: true

require "re2"

module XmlrpcSecurity
  extend ActiveSupport::Concern

  included do
    before_action :configure_xml_security
    before_action :validate_request_size
    before_action :sanitize_logs
    before_action :validate_session
  end

  private

  def configure_xml_security
    # Nokogiri security is configured through options when parsing
    # No global configuration needed as with REXML
  end

  def validate_request_size
    return unless request.content_length && request.content_length > 1.megabyte

    render xml: fault_response(413, "Request too large")
  end

  def sanitize_logs
    # Extract method name for logging if possible
    method_name = nil

    if params[:xml].present?
      begin
        if (m = RE2::Regexp.new("<methodName>([^<]+)</methodName>").match(params[:xml]))
          method_name = m[1]
        end
      rescue StandardError
        # Ignore extraction errors for logging
      end
    end

    # Log structured request information for security auditing
    Rails.logger.info(
      event: "xmlrpc_request",
      ip: request.ip,
      method: method_name,
      timestamp: Time.current.iso8601,
      user_id: current_account&.id
    )
  end

  def validate_session
    if session[:last_activity] && session[:last_activity] < 30.minutes.ago
      render xml: fault_response(401,
                                 "Session expired")
    end
    session[:last_activity] = Time.current
  end

  def validate_method_name(method_name)
    return if RE2::Regexp.new('\\A[a-zA-Z0-9._]+\\z').match?(method_name)

    render xml: fault_response(400, "Invalid method name")
  end

  # Remove duplicate method list since we've moved to a more robust authorization
  # in the XmlrpcController
  def validate_method_access
    # Extract method name from the XML content
    xml_content = params[:xml]

    return if xml_content.blank?

    # Try to parse the method name from the XML
    begin
      # Parse with Nokogiri (with security options)
      doc = Nokogiri::XML(xml_content) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS |
                         Nokogiri::XML::ParseOptions::NONET |   # Prevent network access
                         Nokogiri::XML::ParseOptions::NOENT     # Don't expand entities
        config.strict.nonet                                     # Strict parsing, no network
      end

      # Check document depth for security
      max_depth = 20 # Reduced from 100 to prevent DoS
      if xml_depth(doc) > max_depth
        render xml: fault_response(400, "XML document too deeply nested")
        return
      end

      method_name = doc.at_xpath("//methodName")&.text
      return unless method_name

      validate_method_name(method_name)

      # Log method access for audit trails
      Rails.logger.info(
        event: "xmlrpc_method_access",
        method: method_name,
        ip: request.ip,
        user_id: current_account&.id,
        timestamp: Time.current.iso8601
      )
    rescue Nokogiri::XML::SyntaxError
      render xml: fault_response(400, "Invalid XML-RPC request")
    end
  end

  # Calculate the maximum depth of an XML document
  def xml_depth(node, current_depth = 0)
    return current_depth unless node.respond_to?(:children)

    max = current_depth
    node.children.each do |child|
      depth = xml_depth(child, current_depth + 1)
      max = depth if depth > max
    end
    max
  end

  def fault_response(code, message)
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.methodResponse do
        xml.fault do
          xml.value do
            xml.struct do
              xml.member do
                xml.name "faultCode"
                xml.value do
                  xml.int code
                end
              end
              xml.member do
                xml.name "faultString"
                xml.value do
                  xml.string CGI.escapeHTML(message)
                end
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end
end
