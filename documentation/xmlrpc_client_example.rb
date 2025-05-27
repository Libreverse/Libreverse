#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'builder'
require 'nokogiri'

# Example Ruby client for the Libreverse XML-RPC API
# This demonstrates how to interact with all available endpoints
class LibreverseXmlrpcClient
  attr_writer :session_cookie

  def initialize(base_url = 'https://localhost:3000', session_cookie = nil)
    @base_url = base_url
    @endpoint_url = "#{@base_url}/api/xmlrpc"
    @session_cookie = session_cookie
  end

  # Make an XML-RPC request
  def call_method(method_name, *params)
    # Build XML-RPC request
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0"

    xml_body = xml.methodCall do
      xml.methodName method_name
      xml.params do
        params.each do |param|
          xml.param do
            xml.value do
              encode_value(xml, param)
            end
          end
        end
      end
    end

    # Make HTTP request
    uri = URI(@endpoint_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    # Configure SSL verification
    if uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      # Optionally set custom CA certificate path if needed
      # http.ca_file = '/path/to/ca-certificates.crt'
    end

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'text/xml'
    request['Cookie'] = @session_cookie if @session_cookie
    request.body = xml_body

    response = http.request(request)

    # Parse response
    parse_response(response.body)
  end

  private

  # Encode a Ruby value to XML-RPC format
  def encode_value(xml, value)
    case value
    when String
      xml.string(value)
    when Integer
      xml.int(value)
    when Float
      xml.double(value)
    when TrueClass, FalseClass
      xml.boolean(value ? "1" : "0")
    when Array
      xml.array do
        xml.data do
          value.each do |item|
            xml.value do
              encode_value(xml, item)
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
              encode_value(xml, val)
            end
          end
        end
      end
    else
      xml.string(value.to_s)
    end
  end

  # Parse XML-RPC response
  def parse_response(xml_string)
    doc = Nokogiri::XML(xml_string)

    # Check for fault response
    if (fault_node = doc.at_xpath("//fault"))
      fault_code = fault_node.at_xpath(".//member[name='faultCode']/value/int")&.text
      fault_string = fault_node.at_xpath(".//member[name='faultString']/value/string")&.text
      raise "XML-RPC Fault #{fault_code}: #{fault_string}"
    end

    # Parse successful response
    value_node = doc.at_xpath("//methodResponse/params/param/value")
    parse_value(value_node) if value_node
  end

  # Parse XML-RPC value node
  def parse_value(value_node)
    # Direct text content
    return value_node.text.strip if value_node.children.size == 1 && value_node.children.first.text?

    type_node = value_node.children.find(&:element?)
    return nil unless type_node

    case type_node.name
    when "string"
      type_node.text
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
        name = member.at_xpath("name").text
        value = parse_value(member.at_xpath("value"))
        struct[name] = value
      end
      struct
    else
      type_node.text
    end
  end
end

# Example usage
def demo_client
  client = LibreverseXmlrpcClient.new('http://localhost:3000')

  puts "=== Libreverse XML-RPC API Demo ==="
  puts

  # Public methods (no authentication required)
  puts "1. Getting all approved experiences:"
  begin
    experiences = client.call_method('experiences.all')
    puts "Found #{experiences.length} experiences"
    experiences.first(2).each do |exp|
      puts "  - #{exp['title']} by #{exp['author']}"
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
  puts

  puts "2. Getting approved experiences only:"
  begin
    experiences = client.call_method('experiences.approved')
    puts "Found #{experiences.length} approved experiences"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
  puts

  puts "3. Searching experiences:"
  begin
    results = client.call_method('search.public_query', 'tutorial', 5)
    puts "Search results: #{results.length} experiences found"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
  puts

  puts "4. Getting a specific experience:"
  begin
    experience = client.call_method('experiences.get', 1)
    puts "Experience: #{experience['title']}" if experience
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
  puts

  # The following would require authentication:
  puts "=== Authenticated Methods (require login) ==="
  puts

  puts "To use authenticated methods, you need to:"
  puts "1. Log in through the web interface"
  puts "2. Extract the session cookie"
  puts "3. Set it on the client with: client.session_cookie='your_session_cookie'"
  puts

  puts "Example authenticated methods:"
  puts "- experiences.create(title, description, html_content, author)"
  puts "- experiences.update(id, updates_hash)"
  puts "- experiences.delete(id)"
  puts "- preferences.get(key)"
  puts "- preferences.set(key, value)"
  puts "- preferences.dismiss(key)"
  puts "- preferences.is_dismissed(key)"
  puts "- account.get_info()"
  puts "- search.query(query, limit)"
  puts "- moderation.get_logs()"
  puts

  puts "=== Admin Methods (require admin role) ==="
  puts "- experiences.all_with_unapproved()"
  puts "- experiences.approve(id)"
  puts "- admin.experiences.all()"
  puts "- admin.experiences.approve(id)"
  puts

  # Example of creating an experience (would need authentication)
  puts "Example: Creating an experience (requires authentication):"
  puts <<~EXAMPLE
    client.session_cookie='your_session_cookie_here'

    html_content = '<html><body><h1>My Experience</h1><p>This is my experience content.</p></body></html>'

    experience = client.call_method(
      'experiences.create',
      'My New Experience',           # title
      'A description of my experience', # description
      html_content,                  # HTML content
      'My Name'                      # author (optional)
    )

    puts "Created experience with ID: \#{experience['id']}"
  EXAMPLE
  puts

  # Example of working with preferences
  puts "Example: Working with preferences (requires authentication):"
  puts <<~EXAMPLE
    # Set a preference
    client.call_method('preferences.set', 'dashboard-tutorial', 'true')

    # Get a preference
    pref = client.call_method('preferences.get', 'dashboard-tutorial')
    puts "Preference value: \#{pref['value']}"

    # Dismiss a notification
    client.call_method('preferences.dismiss', 'welcome-message')

    # Check if dismissed
    status = client.call_method('preferences.is_dismissed', 'welcome-message')
    puts "Is dismissed: \#{status['dismissed']}"
  EXAMPLE
end

# Run the demo if this file is executed directly
demo_client if __FILE__ == $PROGRAM_NAME
