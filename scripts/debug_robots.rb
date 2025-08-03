#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script for robots.txt parsing
# Usage: rails runner scripts/debug_robots.rb

puts "=== Robots.txt Debug ==="
puts "Current time: #{Time.current}"
puts

# Test The Sandbox robots.txt parsing specifically
begin
  require 'net/http'
  require 'uri'

  # Manually fetch robots.txt for debugging
  robots_url = "https://www.sandbox.game/robots.txt"
  puts "Fetching robots.txt from: #{robots_url}"

  uri = URI(robots_url)
  response = Net::HTTP.get_response(uri)

  if response.code == '200'
    puts "Status: #{response.code}"
    puts "Content:"
    puts "=" * 50
    puts response.body
    puts "=" * 50
    puts

    # Test with the robots gem directly
    puts "Testing with Robots gem:"
    robots = Robots.new("LibreverseIndexer")

    test_urls = [
      "https://www.sandbox.game/__sitemap__/experiences.xml",
      "https://www.sandbox.game/en/admin/users",
      "https://www.sandbox.game/en/admin/",
      "https://www.sandbox.game/en/me/inventory/",
      "https://www.sandbox.game/en/experiences/"
    ]

    test_urls.each do |test_url|
      allowed = robots.allowed?(test_url)
      puts "  #{test_url}"
      puts "    #{allowed ? 'ALLOWED' : 'BLOCKED'}"
    end

  else
    puts "Failed to fetch robots.txt: #{response.code} #{response.message}"
  end
rescue StandardError => e
  puts "Error: #{e.message}"
end

puts "\n=== Debug Complete ==="
