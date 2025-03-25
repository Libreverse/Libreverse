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
    # Disable external entity processing to prevent XXE attacks
    REXML::Document.entity_expansion_limit = 0

    # Set maximum XML depth to prevent stack overflow attacks
    REXML::Document.max_depth = 100

    # Disable processing of external DTDs
    REXML::Document.entity_expansion_text_limit = 0
  end

  def validate_request_size
    return unless request.content_length && request.content_length > 1.megabyte

      render xml: fault_response(413, "Request too large")
  end

  def sanitize_logs
    # Log structured request information for security auditing
    Rails.logger.info(
      event: "xmlrpc_request",
      ip: request.ip,
      method: params[:method],
      timestamp: Time.current.iso8601,
      user_id: current_account&.id
    )
  end

  def validate_session
    render xml: fault_response(401, "Session expired") if session[:last_activity] && session[:last_activity] < 30.minutes.ago
    session[:last_activity] = Time.current
  end

  def validate_method_name(method_name)
    return if method_name.match?(/\A[a-zA-Z0-9._]+\z/)

      render xml: fault_response(400, "Invalid method name")
  end

  # List of methods that don't require authentication
  PUBLIC_METHODS = %w[
    preferences.isDismissed
    preferences.dismiss
  ].freeze

  def validate_method_access
    method_name = params[:method]
    validate_method_name(method_name)
    return if PUBLIC_METHODS.include?(method_name)

    return if current_account

      render xml: fault_response(401, "Authentication required")
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
end
