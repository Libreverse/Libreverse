#!/usr/bin/env ruby
# frozen_string_literal: true

require "grpc"
require "json"
require "net/http"
require "uri"

# Add the generated gRPC files to the load path
$LOAD_PATH.unshift File.expand_path("../app/grpc", __dir__)

require "libreverse_pb"
require "libreverse_services_pb"

# Example Ruby client for the Libreverse gRPC API
# This demonstrates both native gRPC and HTTP-based gRPC usage
#
# HTTP-based gRPC:
# - Uses the Rails HTTP endpoint (/api/grpc) to tunnel gRPC calls over HTTP
# - Easier to use with existing HTTP infrastructure (load balancers, etc.)
# - No need for a separate gRPC server
#
# Native gRPC:
# - Uses the pure gRPC protocol over a dedicated gRPC server
# - More efficient for high-performance use cases
# - Requires a separate gRPC server to be running
class LibreverseGrpcClient
  def initialize(base_url = "localhost:50051", session_id = nil, use_http = false)
    @base_url = base_url
    @session_id = session_id
    @use_http = use_http

    if @use_http
      # For HTTP-based gRPC, use the Rails server endpoint
      if base_url.include?("localhost:3000")
        @http_endpoint = "http://#{base_url}/api/grpc"
      else
        @http_endpoint = "http://localhost:3000/api/grpc"
      end
    else
      @stub = Libreverse::Grpc::LibreverseService::Stub.new(@base_url, :this_channel_is_insecure)
    end
  end

  # Experience methods
  def get_all_experiences
    request = Libreverse::Grpc::GetAllExperiencesRequest.new

    if @use_http
      http_call("GetAllExperiences", {})
    else
      grpc_call { @stub.get_all_experiences(request, metadata: build_metadata) }
    end
  end

  def get_experience(id)
    request = Libreverse::Grpc::GetExperienceRequest.new(id: id)

    if @use_http
      http_call("GetExperience", { id: id })
    else
      grpc_call { @stub.get_experience(request, metadata: build_metadata) }
    end
  end

  def create_experience(title:, description:, author:)
    request = Libreverse::Grpc::CreateExperienceRequest.new(
      title: title,
      description: description,
      author: author
    )

    if @use_http
      http_call("CreateExperience", { title: title, description: description, author: author })
    else
      grpc_call { @stub.create_experience(request, metadata: build_metadata) }
    end
  end

  def update_experience(id:, title: nil, description: nil, author: nil)
    request_data = { id: id }
    request_data[:title] = title if title
    request_data[:description] = description if description
    request_data[:author] = author if author

    request = Libreverse::Grpc::UpdateExperienceRequest.new(request_data)

    if @use_http
      http_call("UpdateExperience", request_data)
    else
      grpc_call { @stub.update_experience(request, metadata: build_metadata) }
    end
  end

  def delete_experience(id)
    request = Libreverse::Grpc::DeleteExperienceRequest.new(id: id)

    if @use_http
      http_call("DeleteExperience", { id: id })
    else
      grpc_call { @stub.delete_experience(request, metadata: build_metadata) }
    end
  end

  def approve_experience(id)
    request = Libreverse::Grpc::ApproveExperienceRequest.new(id: id)

    if @use_http
      http_call("ApproveExperience", { id: id })
    else
      grpc_call { @stub.approve_experience(request, metadata: build_metadata) }
    end
  end

  def pending_experiences
    request = Libreverse::Grpc::GetPendingExperiencesRequest.new

    if @use_http
      http_call("GetPendingExperiences", {})
    else
      grpc_call { @stub.get_pending_experiences(request, metadata: build_metadata) }
    end
  end

  # Preference methods
  def get_preference(key)
    request = Libreverse::Grpc::GetPreferenceRequest.new(key: key)

    if @use_http
      http_call("GetPreference", { key: key })
    else
      grpc_call { @stub.get_preference(request, metadata: build_metadata) }
    end
  end

  def set_preference(key, value)
    request = Libreverse::Grpc::SetPreferenceRequest.new(key: key, value: value)

    if @use_http
      http_call("SetPreference", { key: key, value: value })
    else
      grpc_call { @stub.set_preference(request, metadata: build_metadata) }
    end
  end

  def dismiss_preference(key)
    request = Libreverse::Grpc::DismissPreferenceRequest.new(key: key)

    if @use_http
      http_call("DismissPreference", { key: key })
    else
      grpc_call { @stub.dismiss_preference(request, metadata: build_metadata) }
    end
  end

  # Admin methods
  def admin_approve_experience(id)
    request = Libreverse::Grpc::AdminApproveExperienceRequest.new(id: id)

    if @use_http
      http_call("AdminApproveExperience", { id: id })
    else
      grpc_call { @stub.admin_approve_experience(request, metadata: build_metadata) }
    end
  end

  private

  def build_metadata
    metadata = {}
    metadata["session-id"] = @session_id if @session_id
    metadata
  end

  def grpc_call
      yield
  rescue GRPC::BadStatus => e
      puts "gRPC Error: #{e.message}"
      puts "Code: #{e.code}"
      puts "Details: #{e.details}"
      nil
  end

  def http_call(method, request_data)
      uri = URI(@http_endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      
      # Only use SSL if the scheme is https
      if uri.scheme == "https"
        http.use_ssl = true
        # Always use proper SSL certificate verification
        # Only disable in specific development/testing scenarios with explicit environment variable
        if ENV["GRPC_CLIENT_SSL_VERIFY"] == "false"
          puts "WARNING: SSL certificate verification disabled for development"
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE # brakeman:ignore SSLVerify
        else
          # Default to proper SSL verification
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
      end

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-Session-ID"] = @session_id if @session_id

      request.body = {
        method: method,
        request: request_data
      }.to_json

      response = http.request(request)
      parsed_response = JSON.parse(response.body)
      
      # Handle gRPC errors in HTTP responses
      if parsed_response.is_a?(Hash) && parsed_response["error"]
        error_message = parsed_response["error"]
        if error_message.start_with?("7:")
          parsed_response["error"] = "Authentication required"
        elsif error_message.start_with?("3:")
          parsed_response["error"] = "Invalid argument"
        elsif error_message.start_with?("5:")
          parsed_response["error"] = "Not found"
        end
      end
      
      parsed_response
  rescue StandardError => e
      puts "HTTP Error: #{e.message}"
      { "error" => "HTTP request failed: #{e.message}" }
  end
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  puts "=== Testing gRPC Client ==="
  puts "Note: Some operations require authentication. This demo shows both authenticated and unauthenticated calls."
  
  # Example using HTTP-based gRPC (no authentication)
  client = LibreverseGrpcClient.new("localhost:3000", nil, use_http: true)

  puts "\n=== Getting all experiences (no auth required) ==="
  experiences = client.get_all_experiences
  puts experiences.inspect

  puts "\n=== Attempting to create experience (requires auth) ==="
  new_experience = client.create_experience(
    title: "Test Experience",
    description: "This is a test experience created via gRPC",
    author: "gRPC Client"
  )
  puts new_experience.inspect
  puts "Note: This failed because authentication is required for creating experiences"

  # Example with session ID (you would get this from login)
  puts "\n=== Testing with session ID ==="
  puts "To test authenticated calls, you would need a valid session ID from logging in"
  authenticated_client = LibreverseGrpcClient.new("localhost:3000", "your-session-id-here", use_http: true)
  
  puts "\n=== Getting preferences (requires auth) ==="
  preference = authenticated_client.get_preference("theme")
  puts preference.inspect

  # Example using native gRPC (requires gRPC server to be running on port 50051)
  puts "\n=== Testing native gRPC ==="
  grpc_client = LibreverseGrpcClient.new("localhost:50051", nil, use_http: false)

  puts "=== Getting all experiences via native gRPC ==="
  experiences = grpc_client.get_all_experiences
  puts experiences.inspect
  
  puts "\n=== gRPC Client Example Complete ==="
  puts "To use this client with authentication:"
  puts "1. Log in to the application to get a session ID"
  puts "2. Pass the session ID when creating the client"
  puts "3. Authenticated calls will then work for creating/modifying experiences"
end
