#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to check production host configuration
# This reads the production.rb file directly without loading Rails

puts "Production Host Configuration Check"
puts "===================================="
puts ""

# Read the production configuration file
production_config = File.read(File.expand_path("../config/environments/production.rb", __dir__))

puts "Production environment configuration:"
puts ""

# Extract host-related configuration
host_lines = production_config.split("\n").select { |line| line.match?(/(hosts|ALLOWED_HOSTS|localhost|127\.0\.0\.1)/i) }

if host_lines.empty?
  puts "No host configuration found in production.rb"
else
  puts "Host-related configuration lines:"
  host_lines.each do |line|
    puts "  #{line.strip}"
  end
end

puts ""
puts "Expected hosts that should be allowed:"
puts "  - localhost"
puts "  - localhost:3000"
puts "  - 127.0.0.1"
puts "  - 127.0.0.1:3000"
puts "  - Plus any domain configured in LibreverseInstance.allowed_hosts"
puts ""

# Check if ALLOWED_HOSTS environment variable is set
if ENV["ALLOWED_HOSTS"]
  puts "ALLOWED_HOSTS environment variable is set:"
  puts "  #{ENV['ALLOWED_HOSTS']}"
else
  puts "ALLOWED_HOSTS environment variable is not set"
end

puts ""
puts "To test this configuration in production, you can:"
puts "1. Make a request to your app from localhost:3000"
puts "2. Check the production logs for any 'Blocked hosts' errors"
puts "3. Use curl to test: curl -H 'Host: localhost:3000' http://your-app-url/"
puts ""
puts "If you see 'Blocked hosts' errors, the host configuration may need adjustment."
