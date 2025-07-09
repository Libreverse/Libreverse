#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify production host configuration
# Run this in production to check if localhost:3000 is allowed

ENV["RAILS_ENV"] = "production"
require_relative "../config/environment"

puts "Production Host Configuration Test"
puts "=================================="
puts ""

# Show current allowed hosts
puts "Currently allowed hosts:"
Rails.application.config.hosts.each do |host|
  puts "  - #{host}"
end
puts ""

# Test specific hosts
test_hosts = [
  "localhost",
  "localhost:3000",
  "127.0.0.1",
  "127.0.0.1:3000"
]

puts "Testing host authorization:"
test_hosts.each do |host|
    # Create a mock request with the host
    request = ActionDispatch::Request.new({
                                            "HTTP_HOST" => host,
                                            "REQUEST_METHOD" => "GET",
                                            "PATH_INFO" => "/",
                                            "SCRIPT_NAME" => "",
                                            "QUERY_STRING" => "",
                                            "SERVER_NAME" => host.split(":").first,
                                            "SERVER_PORT" => host.split(":").last == host ? "80" : host.split(":").last,
                                            "rack.input" => StringIO.new,
                                            "rack.errors" => StringIO.new,
                                            "rack.url_scheme" => "http"
                                          })

    # Test if this host would be allowed
    host_auth = ActionDispatch::HostAuthorization.new(
      ->(_env) { [ 200, {}, [ "OK" ] ] },
      Rails.application.config.hosts
    )

    # Simulate the middleware check
    response = host_auth.call(request.env)

    if response[0] == 200
      puts "  ✓ #{host} - ALLOWED"
    else
      puts "  ✗ #{host} - BLOCKED"
    end
rescue StandardError => e
    puts "  ? #{host} - ERROR: #{e.message}"
end

puts ""
puts "Environment Variables:"
puts "  ALLOWED_HOSTS: #{ENV['ALLOWED_HOSTS'] || 'not set'}"
puts ""
puts "Test completed!"
