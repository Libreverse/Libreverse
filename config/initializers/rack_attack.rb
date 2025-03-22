# Configure Rack::Attack for rate limiting and security
module Rack
  class Attack
    # Throttle high volumes of requests by IP address
    throttle("req/ip", limit: 300, period: 5.minutes) do |req|
      req.ip unless req.path.start_with?("/assets")
    end

    # Throttle POST requests to /api/xmlrpc by IP address
    throttle("xmlrpc/ip", limit: 30, period: 1.minute) do |req|
      req.ip if req.path == "/api/xmlrpc" && req.post?
    end

    # Block suspicious requests for XML-RPC API
    blocklist("block suspicious XML-RPC requests") do |req|
      if req.path == "/api/xmlrpc" && req.post?
        # Block requests with suspicious content types
        content_type = req.get_header("CONTENT_TYPE") || req.get_header("Content-Type")
        
        # Block if no valid content type
        !(content_type&.include?("multipart/form-data") ||
          content_type&.include?("text/xml") ||
          content_type&.include?("application/xml"))
      end
    end

    # Block requests with non-standard User-Agents (bots, vulnerability scanners)
    blocklist("block bots and vulnerability scanners") do |req|
      blocked_user_agents = %w[
        nmap nikto sqlmap dirbuster nessus acunetix burp
        metasploit masscan wget libwww-perl python-requests
      ]

      user_agent = req.user_agent.to_s.downcase

      # Block if the user agent matches any in the blocked list
      blocked_user_agents.any? { |ua| user_agent.include?(ua) } if req.path == "/api/xmlrpc" && req.post?
    end

    # Throttle XML-RPC failed login attempts
    throttle("xmlrpc/login_failures", limit: 5, period: 20.minutes) do |req|
      if req.path == "/api/xmlrpc" && req.post?
        # Check body content
        body = req.body.read
        req.body.rewind

        # Simple check for authentication attempts
        req.ip if body.include?("methodCall") && body.include?("authenticate")
      end
    end

    # XML-RPC fault response generator with correct XML format using <name> tags
    # This follows the XML-RPC specification
    def self.xmlrpc_fault_response(code, message)
      %(<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>#{code}</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>#{message}</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>)
    end

    # Set up response handling with new responder methods (not deprecated ones)
    self.throttled_responder = lambda do |_env|
      [
        429, # status
        { "Content-Type" => "text/xml" },
        [ xmlrpc_fault_response(429, "Rate limit exceeded") ]
      ]
    end

    self.blocklisted_responder = lambda do |_env|
      [
        403, # status
        { "Content-Type" => "text/xml" },
        [ xmlrpc_fault_response(403, "Access denied") ]
      ]
    end
  end
end
