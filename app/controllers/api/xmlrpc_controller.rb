require "nokogiri"
require "cgi"

module Api
  class XmlrpcController < ApplicationController
    include XmlrpcSecurity

    # Keep CSRF protection enabled but handle it properly for XMLRPC
    # Using a specific exception for XMLRPC requests instead of skipping verification
    protect_from_forgery with: :exception, unless: -> { valid_xmlrpc_request? }
    before_action :apply_rate_limit
    before_action :current_account
    before_action :validate_method_access
    before_action :validate_content_type

    # POST /api/xmlrpc
    def endpoint
      # Read the XML from the FormData
      xml_content = params[:xml]

      # Ensure we have content
      if xml_content.blank?
        render xml: fault_response(400, "Empty request body")
        return
      end

      begin
        # Parse the XML using Nokogiri with security options
        doc = Nokogiri::XML(xml_content) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS |
                           Nokogiri::XML::ParseOptions::NONET |  # Prevent network access
                           Nokogiri::XML::ParseOptions::NOENT    # Don't expand entities
          config.strict.nonet                                    # Strict parsing, no network
        end

        # Apply a processing timeout
        Timeout.timeout(3) do
          # Validate the XML-RPC structure
          method_name = doc.at_xpath("//methodName")&.text
          unless method_name
            render xml: fault_response(400, "Invalid XML-RPC request: No methodName element found")
            return
          end

          # Extract parameters
          params = []
          doc.xpath("//methodCall/params/param").each do |param|
            value_element = param.at_xpath("value")
            params << parse_value(value_element) if value_element
          end

          # Validate permissions for the method
          unless permitted_method?(method_name)
            render xml: fault_response(403, "Method not allowed")
            return
          end

          # Process the method call
          result = process_method_call(method_name, params)

          # Generate the XML response
          response_xml = generate_response(result)

          render xml: response_xml
        end
      rescue Timeout::Error
        render xml: fault_response(408, "Request timeout")
      rescue Nokogiri::XML::SyntaxError
        # Mark this request as having failed XML parsing for rate limiting
        request.env["xmlrpc.parse_failed"] = true
        render xml: fault_response(400, "Invalid XML-RPC request")
      rescue StandardError => e
        Rails.logger.error("XML-RPC error: #{e.message}")
        render xml: fault_response(500, "Internal server error")
      end
    end

    private

    def valid_xmlrpc_request?
      request.path == "/api/xmlrpc" && request.post? &&
        (request.content_type&.include?("text/xml") ||
         request.content_type&.include?("application/xml"))
    end

    def validate_content_type
      valid_types = [ "text/xml", "application/xml" ]

      unless valid_types.any? { |type| request.content_type&.include?(type) }
        render xml: fault_response(415, "Unsupported content type. Use text/xml or application/xml"), status: :unsupported_media_type
        return false
      end

      true
    end

    def permitted_method?(method_name)
      return false unless method_name.match?(/\A[a-zA-Z0-9._]+\z/)

      # Methods requiring authentication
      authenticated_methods = %w[
        experiences.create
        experiences.delete
        experiences.update
      ]

      # Public methods (no authentication required)
      public_methods = %w[
        experiences.all
      ]

      if authenticated_methods.include?(method_name) && !current_account
        # Require authentication for these methods
        return false
      end

      # Check if method is either public or authenticated
      public_methods.include?(method_name) || authenticated_methods.include?(method_name)
    end

    def parse_value(value_element)
      # Check for direct text content (string value)
      return CGI.escapeHTML(value_element.text.strip) if value_element.children.size == 1 && value_element.children.first.text?

      # Get the type node - first element child of value
      type_node = value_element.element_children.first

      return nil unless type_node

      case type_node.name
      when "string"
        CGI.escapeHTML(type_node.text)
      when "int", "i4"
        type_node.text.to_i
      when "boolean"
        type_node.text == "1"
      when "double"
        type_node.text.to_f
      when "array"
        type_node.xpath(".//value").map { |v| parse_value(v) }
      when "struct"
        struct = {}
        type_node.xpath("./member").each do |member|
          name = CGI.escapeHTML(member.at_xpath("name").text)
          value = parse_value(member.at_xpath("value"))
          struct[name] = value
        end
        struct
      else
        CGI.escapeHTML(type_node.text)
      end
    end

    def process_method_call(method_name, _params)
      case method_name
      when "experiences.all"
        # Get all experiences on the instance, sorted by most recent first
        experiences = Experience.all.order(created_at: :desc)
        serialize_experiences(experiences)
      else
        raise "Unknown method: #{method_name}"
      end
    end

    # Helper method to serialize experiences into a format suitable for XML-RPC
    def serialize_experiences(experiences)
      experiences.map do |experience|
        {
          "id" => experience.id,
          "title" => experience.title,
          "description" => experience.description,
          "author" => experience.author,
          "created_at" => experience.created_at.iso8601,
          "updated_at" => experience.updated_at.iso8601
        }
      end
    end

    def generate_response(result)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.methodResponse do
          xml.params do
            xml.param do
              xml.value do
                add_typed_value(xml, result)
              end
            end
          end
        end
      end
      builder.to_xml
    end

    # Helper method to add a typed value to XML-RPC response
    def add_typed_value(xml, value)
      case value
      when TrueClass, FalseClass
        xml.boolean(value ? "1" : "0")
      when Integer
        xml.int(value.to_s)
      when Float
        xml.double(value.to_s)
      when Array
        xml.array do
          xml.data do
            value.each do |item|
              xml.value do
                add_typed_value(xml, item)
              end
            end
          end
        end
      when Hash
        xml.struct do
          value.each do |key, val|
            xml.member do
              xml.name(key.to_s)
              xml.value do
                add_typed_value(xml, val)
              end
            end
          end
        end
      else
        xml.string(CGI.escapeHTML(value.to_s))
      end
    end

    def apply_rate_limit
      key = "xmlrpc_rate_limit:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)

      return unless count > 30

      render xml: fault_response(429, "Rate limit exceeded")
    end

    def current_account
      @current_account ||= Account.find_by(id: session[:account_id])
    end

    def fault_response(code, message)
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
  end
end
