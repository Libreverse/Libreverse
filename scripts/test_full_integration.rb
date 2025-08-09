#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the actual robots parser caching with integrity
require_relative '../app/indexers/base_indexer'

puts "=== Testing Robots Parser Cache with Integrity ==="

# Create a test indexer
class TestableIndexer < BaseIndexer
  # Make the methods public for testing
  public :get_robots_parser, :generate_cache_integrity_hash, :verify_cache_integrity
end

indexer = TestableIndexer.new

# Test the integrity methods directly first
puts "\n1. Testing integrity methods..."
test_data = "test marshal data"
test_domain = "example.com"

begin
  hash = indexer.generate_cache_integrity_hash(test_data, test_domain)
  puts "✓ Hash generated: #{hash[0..30]}..."

  verify_result = indexer.verify_cache_integrity(test_data, test_domain, hash)
  puts "✓ Verification successful: #{verify_result}"

  if verify_result
    puts "\n🎉 Integrity checking works!"

    # Now test with actual robots parser if integrity works
    puts "\n2. Testing with actual robots parser (this will try to fetch robots.txt)..."
    puts "Note: This might fail if robots.txt is not accessible, but integrity should still work"

    # Test with a domain that should have robots.txt
    test_result = indexer.get_robots_parser("https://www.google.com")
    puts "✓ Robots parser test completed: #{test_result.class}"

  else
    puts "❌ Integrity verification failed"
  end
rescue StandardError => e
  puts "❌ Error: #{e.class}: #{e.message}"
  puts e.backtrace.first(3)
end
