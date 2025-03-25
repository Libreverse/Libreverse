require "rexml/document"
require "cgi"

module Api
  class XmlrpcController < ApplicationController
    include XmlrpcSecurity

    skip_before_action :verify_authenticity_token
    before_action :apply_rate_limit
    before_action :current_account
    before_action :validate_method_access

    # POST /api/xmlrpc
    def endpoint
      # Read the XML from the FormData
      xml_content = params[:xml]

      # Ensure we have content
      if xml_content.blank?
        render xml: fault_response(400, "Empty request body")
        return
      end

      # Ensure the XML starts with the XML declaration
      xml_content = "<?xml version=\"1.0\"?>#{xml_content}" unless xml_content.start_with?("<?xml")

      begin
        # Parse the XML using REXML with timeout
        Timeout.timeout(5) do
          doc = REXML::Document.new(xml_content)

          # Validate the XML-RPC structure
          method_call = doc.elements["methodCall"]
          unless method_call
            render xml: fault_response(400, "Invalid XML-RPC request: No methodCall element found")
            return
          end

          method_name = method_call.elements["methodName"]&.text
          unless method_name
            render xml: fault_response(400, "Invalid XML-RPC request: No methodName element found")
            return
          end

          # Extract parameters
          params = []
          method_call.elements.each("params/param") do |param|
            value = param.elements["value"]
            params << parse_value(value) if value
          end

          # Process the method call
          result = process_method_call(method_name, params)

          # Generate the XML response
          response_xml = generate_response(result)
          render xml: response_xml
        end
      rescue Timeout::Error
        render xml: fault_response(408, "Request timeout")
      rescue REXML::ParseException
        render xml: fault_response(400, "Invalid XML-RPC request")
      rescue StandardError => e
        Rails.logger.error("XML-RPC error: #{e.message}")
        render xml: fault_response(500, "Internal server error")
      end
    end

    private

    def parse_value(value_element)
      return nil unless value_element&.elements&.first

      case value_element.elements.first.name
      when "string"
        CGI.escapeHTML(value_element.elements.first.text)
      when "int", "i4"
        value_element.elements.first.text.to_i
      when "boolean"
        value_element.elements.first.text == "1"
      when "double"
        value_element.elements.first.text.to_f
      when "array"
        value_element.elements["data/array/data/value"].map { |v| parse_value(v) }
      when "struct"
        struct = {}
        value_element.elements.each("member") do |member|
          name = CGI.escapeHTML(member.elements["name"].text)
          value = parse_value(member.elements["value"])
          struct[name] = value
        end
        struct
      else
        CGI.escapeHTML(value_element.elements.first.text)
      end
    end

    def process_method_call(method_name, params)
      case method_name
      when "preferences.isDismissed"
        preference_key = params.first
        UserPreference.dismissed?(current_account&.id, preference_key)
      when "preferences.dismiss"
        preference_key = params.first
        UserPreference.dismiss(current_account&.id, preference_key)
        true
      else
        raise "Unknown method: #{method_name}"
      end
    end

    def generate_response(result)
      doc = REXML::Document.new
      doc.add(REXML::XMLDecl.new("1.0", "UTF-8"))

      method_response = REXML::Element.new("methodResponse")
      doc.add(method_response)

      params = REXML::Element.new("params")
      method_response.add(params)

      param = REXML::Element.new("param")
      params.add(param)

      value = REXML::Element.new("value")
      param.add(value)

      if result.is_a?(TrueClass) || result.is_a?(FalseClass)
        bool = REXML::Element.new("boolean")
        bool.text = result ? "1" : "0"
        value.add(bool)
      else
        string = REXML::Element.new("string")
        string.text = CGI.escapeHTML(result.to_s)
        value.add(string)
      end

      doc.to_s
    end

    def fault_response(code, message)
      doc = REXML::Document.new
      doc.add(REXML::XMLDecl.new("1.0", "UTF-8"))

      method_response = REXML::Element.new("methodResponse")
      doc.add(method_response)

      fault = REXML::Element.new("fault")
      method_response.add(fault)

      value = REXML::Element.new("value")
      fault.add(value)

      struct = REXML::Element.new("struct")
      value.add(struct)

      # Add faultCode
      member_code = REXML::Element.new("member")
      struct.add(member_code)

      name_code = REXML::Element.new("name")
      name_code.text = "faultCode"
      member_code.add(name_code)

      value_code = REXML::Element.new("value")
      member_code.add(value_code)

      int_code = REXML::Element.new("int")
      int_code.text = code.to_s
      value_code.add(int_code)

      # Add faultString
      member_string = REXML::Element.new("member")
      struct.add(member_string)

      name_string = REXML::Element.new("name")
      name_string.text = "faultString"
      member_string.add(name_string)

      value_string = REXML::Element.new("value")
      member_string.add(value_string)

      string = REXML::Element.new("string")
      string.text = CGI.escapeHTML(message)
      value_string.add(string)

      doc.to_s
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
  end
end
