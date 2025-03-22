require "rexml/document"
require "cgi"

module Api
  class XmlrpcController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :apply_rate_limit
    before_action :current_account

    # POST /api/xmlrpc
    def endpoint
      Rails.logger.info "XML-RPC request headers: #{request.headers.to_h.select { |k, _| k.start_with?('HTTP_') }}"
      Rails.logger.info "XML-RPC request content type: #{request.content_type}"

      # Read the XML from the FormData
      xml_content = params[:xml]

      Rails.logger.info "XML-RPC request body: #{xml_content}"

      # Ensure we have content
      if xml_content.blank?
        Rails.logger.error "XML-RPC error: Empty request body"
        render xml: fault_response(400, "Empty request body")
        return
      end

      # Ensure the XML starts with the XML declaration
      unless xml_content.start_with?("<?xml")
        xml_content = "<?xml version=\"1.0\"?>#{xml_content}"
        Rails.logger.info "Added XML declaration to request: #{xml_content}"
      end

      begin
        # Parse the XML using REXML
        doc = REXML::Document.new(xml_content)
        Rails.logger.info "Parsed XML successfully. Root element: #{doc.root&.name}, children: #{doc.root&.children&.map(&:name)}"

        # Validate the XML-RPC structure
        method_call = doc.elements["methodCall"]
        unless method_call
          Rails.logger.error "XML-RPC error: No methodCall element found"
          render xml: fault_response(400, "Invalid XML-RPC request: No methodCall element found")
          return
        end

        method_name = method_call.elements["methodName"]&.text
        unless method_name
          Rails.logger.error "XML-RPC error: No methodName element found"
          render xml: fault_response(400, "Invalid XML-RPC request: No methodName element found")
          return
        end

        # Extract parameters
        params = []
        method_call.elements.each("params/param") do |param|
          value = param.elements["value"]
          params << parse_value(value) if value
        end

        Rails.logger.info "Processing method call: #{method_name} with params: #{params.inspect}"

        # Process the method call
        result = process_method_call(method_name, params)

        # Generate the XML response
        response_xml = generate_response(result)
        Rails.logger.info "Generated response: #{response_xml}"

        render xml: response_xml
      rescue REXML::ParseException => e
        Rails.logger.error "XML-RPC error: #{e.message}"
        render xml: fault_response(400, "Invalid XML-RPC request: #{e.message}")
      rescue StandardError => e
        Rails.logger.error "XML-RPC error: #{e.message}"
        render xml: fault_response(500, "Internal server error: #{e.message}")
      end
    end

    private

    def parse_value(value_element)
      case value_element.elements.first&.name
      when "string"
        value_element.elements.first.text
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
          name = member.elements["name"].text
          value = parse_value(member.elements["value"])
          struct[name] = value
        end
        struct
      else
        value_element.elements.first&.text
      end
    end

    def process_method_call(method_name, params)
      case method_name
      when "preferences.isDismissed"
        preference_key = params.first
        UserPreference.dismissed?(current_account.id, preference_key)
      when "preferences.dismiss"
        preference_key = params.first
        UserPreference.dismiss(current_account.id, preference_key)
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
        string.text = result.to_s
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
      string.text = message
      value_string.add(string)

      doc.to_s
    end

    def apply_rate_limit
      key = "xmlrpc_rate_limit:#{current_account.id}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)

      return unless count > 30

        render xml: fault_response(429, "Rate limit exceeded")
    end

    def current_account
      @current_account ||= Account.find_by(id: session[:account_id])
    end
  end
end
