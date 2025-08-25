# Libreverse XML-RPC API Documentation

This document describes the secure XML-RPC API for Libreverse.

## Overview

The Libreverse API uses XML-RPC over HTTPS for secure, reliable communication. XML-RPC is a remote procedure call protocol which uses XML to encode its calls and HTTP as a transport mechanism.

## Authentication

API access requires authentication through session cookies for most methods. You must obtain a valid session by logging in through the web interface. The session cookie must be included in all API requests that require authentication.

Some methods are available without authentication for public access.

## Endpoint

All XML-RPC calls should be made to the following endpoint:

```http
POST /api/xmlrpc
```

## Security Measures

The API implements multiple security mechanisms:

- All requests must be made over HTTPS
- Rate limiting is enforced to prevent abuse (30 requests per minute per IP)
- Authentication is required for most methods
- Admin role is required for administrative methods
- Input validation is performed on all parameters
- Full audit logging of all API calls
- 3-second processing timeout for all requests

## Available Methods

### Public Methods (No Authentication Required)

#### experiences.all

Retrieves all approved experiences for unauthenticated users, or all experiences for admin users.

**Parameters:** None

**Returns:** Array of experience objects

#### experiences.get

Retrieves a specific experience by ID.

**Parameters:**

- `id` (integer): Experience ID

**Returns:** Experience object or error if not found/accessible

#### experiences.approved

Retrieves all approved experiences.

**Parameters:** None

**Returns:** Array of approved experience objects

#### search.public_query

Searches through approved experiences.

**Parameters:**

- `query` (string): Search query (optional, max 50 characters)
- `limit` (integer): Maximum results to return (optional, default 20, max 100)

**Returns:** Array of matching experience objects

### Authenticated Methods (Session Required)

#### experiences.create

Creates a new experience.

**Parameters:**

- `title` (string): Experience title (required, max 255 characters)
- `description` (string): Experience description (optional, max 2000 characters)
- `html_content` (string): HTML content for the experience (required)
- `author` (string): Author name (optional, defaults to current user's username)

**Returns:** Created experience object

#### experiences.update

Updates an existing experience owned by the current user.

**Parameters:**

- `id` (integer): Experience ID
- `updates` (struct): Object containing fields to update (title, description, author)

**Returns:** Updated experience object

#### experiences.delete

Deletes an experience owned by the current user.

**Parameters:**

- `id` (integer): Experience ID

**Returns:** Success confirmation

#### experiences.pending_approval

Gets experiences pending approval. Admins see all pending experiences, regular users see only their own.

**Parameters:** None

**Returns:** Array of pending experience objects

#### preferences.get

Gets a user preference value.

**Parameters:**

- `key` (string): Preference key (must be from allowed list)

**Returns:** Preference object with key and value

**Allowed preference keys:**

- `dashboard-tutorial`
- `search-tutorial`
- `welcome-message`
- `feature-announcement`
- `theme-selection`
- `sidebar_expanded`
- `sidebar_hovered`
- `drawer_expanded_main`
- `locale`

#### preferences.set

Sets a user preference value.

**Parameters:**

- `key` (string): Preference key (must be from allowed list)
- `value` (string): Preference value

**Returns:** Success confirmation with key and normalized value

#### preferences.dismiss

Marks a preference as dismissed.

**Parameters:**

- `key` (string): Preference key to dismiss

**Returns:** Success confirmation

#### preferences.is_dismissed

Checks if a preference has been dismissed.

**Parameters:**

- `key` (string): Preference key to check

**Returns:** Object with key and dismissed status (boolean)

#### account.get_info

Gets information about the current user account.

**Parameters:** None

**Returns:** Account information object

#### search.query

Searches through experiences. Admins can search all experiences, regular users search only approved ones.

**Parameters:**

- `query` (string): Search query (optional, max 50 characters)
- `limit` (integer): Maximum results to return (optional, default 20, max 100)

**Returns:** Array of matching experience objects

#### moderation.get_logs

Gets moderation logs. Admins see all logs (last 100), regular users see only their own logs.

**Parameters:** None

**Returns:** Array of moderation log objects

### Admin-Only Methods (Admin Role Required)

#### experiences.all_with_unapproved

Gets all experiences including unapproved ones.

**Parameters:** None

**Returns:** Array of all experience objects

#### experiences.approve

Approves an experience.

**Parameters:**

- `id` (integer): Experience ID to approve

**Returns:** Updated experience object

#### admin.experiences.all

Gets all experiences (admin interface).

**Parameters:** None

**Returns:** Array of all experience objects

#### admin.experiences.approve

Approves an experience (admin interface).

**Parameters:**

- `id` (integer): Experience ID to approve

**Returns:** Updated experience object

## Data Structures

### Experience Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>title</name><value><string>Experience Title</string></value></member>
  <member><name>description</name><value><string>Experience description</string></value></member>
  <member><name>author</name><value><string>Author Name</string></value></member>
  <member><name>approved</name><value><boolean>1</boolean></value></member>
  <member><name>account_id</name><value><int>456</int></value></member>
  <member><name>has_html_file</name><value><boolean>1</boolean></value></member>
  <member><name>created_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
  <member><name>updated_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
</struct>
```

### Account Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>username</name><value><string>user123</string></value></member>
  <member><name>admin</name><value><boolean>0</boolean></value></member>
  <member><name>guest</name><value><boolean>0</boolean></value></member>
  <member><name>status</name><value><string>verified</string></value></member>
</struct>
```

### Moderation Log Object

```xml
<struct>
  <member><name>id</name><value><int>123</int></value></member>
  <member><name>field</name><value><string>title</string></value></member>
  <member><name>model_type</name><value><string>Experience</string></value></member>
  <member><name>content</name><value><string>Flagged content</string></value></member>
  <member><name>reason</name><value><string>inappropriate language</string></value></member>
  <member><name>account_id</name><value><int>456</int></value></member>
  <member><name>violations</name><value><array>...</array></value></member>
  <member><name>created_at</name><value><string>2024-01-01T12:00:00Z</string></value></member>
</struct>
```

## Example Requests

### Creating an Experience

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>experiences.create</methodName>
  <params>
    <param><value><string>My Experience Title</string></value></param>
    <param><value><string>A description of my experience</string></value></param>
    <param><value><string>&lt;html&gt;&lt;body&gt;&lt;h1&gt;Hello World&lt;/h1&gt;&lt;/body&gt;&lt;/html&gt;</string></value></param>
    <param><value><string>Author Name</string></value></param>
  </params>
</methodCall>
```

### Getting User Preferences

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>preferences.get</methodName>
  <params>
    <param><value><string>dashboard-tutorial</string></value></param>
  </params>
</methodCall>
```

### Searching Experiences

```xml
<?xml version="1.0"?>
<methodCall>
  <methodName>search.public_query</methodName>
  <params>
    <param><value><string>tutorial</string></value></param>
    <param><value><int>10</int></value></param>
  </params>
</methodCall>
```

## Error Handling

Errors are returned as XML-RPC fault responses with a fault code and fault string.

**Example error response:**

```xml
<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>400</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Invalid preference key</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>
```

## Common Fault Codes

- `400`: Bad request (e.g., invalid parameters, missing required fields)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (access denied or insufficient permissions)
- `404`: Method not found
- `408`: Request timeout (processing took longer than 3 seconds)
- `415`: Unsupported content type
- `429`: Rate limit exceeded (more than 30 requests per minute)
- `500`: Internal server error

## Rate Limiting

The API enforces rate limiting of 30 requests per minute per IP address. When the rate limit is exceeded, the API returns a fault response with code 429.

## Ruby client example

<!-- markdownlint-disable MD046 -->

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
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
    headers = {
      'Content-Type' => 'text/xml'
    }
    headers['Cookie'] = @session_cookie if @session_cookie

    response = HTTParty.post(@endpoint_url,
                             body: xml_body,
                             headers: headers,
                             verify: true) # Enable SSL verification

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
end
```

<!-- markdownlint-enable MD046 -->
