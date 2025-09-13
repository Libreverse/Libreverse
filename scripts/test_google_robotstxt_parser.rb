#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick smoke test for google_robotstxt_parser gem
# Usage:
#   rails runner scripts/test_google_robotstxt_parser.rb
# Or directly via Ruby:
#   ruby scripts/test_google_robotstxt_parser.rb

require 'bundler/setup'
require 'net/http'
require 'uri'

puts "=== google_robotstxt_parser smoke test ==="
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
time_str = if Time.respond_to?(:current)
  Time.current.to_s
else
  Time.zone.now.to_s
end
puts "Time: #{time_str}"
puts

begin
  require 'google_robotstxt_parser'
  require 'robotstxt'
rescue LoadError => e
  warn "Failed to require gem: #{e.message}"
  exit 1
end

## No need to include the module; we call Robotstxt.allowed_by_robots directly

# Fetch a known robots.txt for testing
robots_url = ENV.fetch('ROBOTS_URL') { 'https://www.sandbox.game/robots.txt' }
user_agent = ENV.fetch('USER_AGENT') { 'LibreverseTester' }
base_url   = ENV.fetch('BASE_URL') { 'https://www.sandbox.game' }

puts "Fetching robots.txt from: #{robots_url}"
uri = URI(robots_url)
res = Net::HTTP.get_response(uri)

if res.code != '200'
  warn "Failed to fetch robots.txt: #{res.code} #{res.message}"
  exit 2
end

robots_content = res.body
puts "Robots.txt bytes: #{robots_content.bytesize}"
puts

# A few URLs to probe
urls = [
  File.join(base_url, '/__sitemap__/experiences.xml'),
  File.join(base_url, '/en/admin/users'),
  File.join(base_url, '/en/me/inventory/'),
  File.join(base_url, '/en/experiences/')
]

puts "Testing allowed_by_robots(user_agent=#{user_agent.inspect})"
urls.each do |url|
  allowed = Robotstxt.allowed_by_robots(robots_content, user_agent, url)
  puts "  #{url} => #{allowed ? 'ALLOWED' : 'BLOCKED'}"
end

puts "\n=== Done ==="
