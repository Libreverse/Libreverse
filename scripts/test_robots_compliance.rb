#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for robots.txt compliance checking
# Usage: rails runner scripts/test_robots_compliance.rb

puts "=== Robots.txt Compliance Test ==="
puts "Current time: #{Time.current}"
puts

# Test URLs and expected results
test_cases = [
  {
    name: "Decentraland Catalyst API",
    url: "https://peer.decentraland.org/content/entities/scenes?pointer=0,0",
    expected: true,
    indexer: "decentraland"
  },
  {
    name: "Sandbox Sitemap",
    url: "https://www.sandbox.game/__sitemap__/experiences.xml",
    expected: true, # Based on their robots.txt allowing everything
    indexer: "sandbox"
  },
  {
    name: "Sandbox Admin (should be blocked)",
    url: "https://www.sandbox.game/en/admin/users",
    expected: false, # Based on their robots.txt disallowing /en/admin/
    indexer: "sandbox"
  }
]

puts "Testing robots.txt compliance for various URLs:"
puts

test_cases.each_with_index do |test_case, i|
  puts "#{i + 1}. #{test_case[:name]}"
  puts "   URL: #{test_case[:url]}"
  puts "   Expected: #{test_case[:expected] ? 'ALLOWED' : 'BLOCKED'}"

  begin
    # Create appropriate indexer
    indexer = if test_case[:indexer] == "decentraland"
                Metaverse::DecentralandIndexer.new
    else
                Metaverse::SandboxIndexer.new
    end

    # Test robots.txt compliance
    allowed = indexer.send(:robots_allowed?, test_case[:url])

    status = allowed ? "ALLOWED" : "BLOCKED"
    result = allowed == test_case[:expected] ? "✅ PASS" : "❌ FAIL"

    puts "   Result: #{status} #{result}"

    # If this URL should be allowed, test getting the robots parser
    if allowed
      begin
        uri = URI.parse(test_case[:url])
        domain = "#{uri.scheme}://#{uri.host}"
        robots_parser = indexer.send(:get_robots_parser, domain)
        puts "   Parser: #{robots_parser.class.name}"

        # Test some other values (like sitemaps)
        other_values = robots_parser.other_values(domain)
        puts "   Other values: #{other_values.keys.join(', ')}" if other_values.present?
      rescue StandardError => e
        puts "   Parser error: #{e.message}"
      end
    end
  rescue StandardError => e
    puts "   ❌ ERROR: #{e.class.name} - #{e.message}"
  end

  puts
end

# Test caching behavior
puts "=== Testing Robots Parser Caching ==="
puts

begin
  indexer = Metaverse::SandboxIndexer.new
  domain = "https://www.sandbox.game"

  puts "First request (should create and cache parser):"
  start_time = Time.current
  parser1 = indexer.send(:get_robots_parser, domain)
  time1 = ((Time.current - start_time) * 1000).round(2)
  puts "  Time: #{time1}ms"
  puts "  Parser: #{parser1.class.name}"

  puts "\nSecond request (should use cached parser):"
  start_time = Time.current
  parser2 = indexer.send(:get_robots_parser, domain)
  time2 = ((Time.current - start_time) * 1000).round(2)
  puts "  Time: #{time2}ms"
  puts "  Parser: #{parser2.class.name}"

  cache_hit = time2 < time1
  puts "  Cache #{cache_hit ? 'HIT' : 'MISS'} (#{cache_hit ? '✅' : '❌'})"
rescue StandardError => e
  puts "❌ Caching test failed: #{e.message}"
end

puts "\n=== Test Complete ==="
