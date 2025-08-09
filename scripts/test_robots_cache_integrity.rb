#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for robots cache integrity checking
puts "🧪 Testing Robots Cache Integrity System"
puts "=" * 50

# Create a test subclass to access private methods
class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

indexer = TestIndexer.new
test_data = Marshal.dump("test robots parser data")
test_domain = "example.com"

puts "1. Generating integrity hash for test data..."
hash = indexer.generate_cache_integrity_hash(test_data, test_domain)
puts "   ✓ Hash generated: #{hash[0..50]}..."

puts "\n2. Verifying with correct data..."
result = indexer.verify_cache_integrity(test_data, test_domain, hash)
puts "   ✓ Verification result: #{result}"

puts "\n3. Testing with tampered data..."
tampered_data = "#{test_data}tampered"
result = indexer.verify_cache_integrity(tampered_data, test_domain, hash)
puts "   ✓ Tampered data verification: #{result}"

puts "\n4. Testing with different domain..."
result = indexer.verify_cache_integrity(test_data, "different.com", hash)
puts "   ✓ Different domain verification: #{result}"

puts "\n5. Testing full cache workflow..."
begin
  # Test the actual cache methods
  indexer.get_robots_parser("httpbin.org")
  puts "   ✓ Successfully created and cached robots parser for httpbin.org"

  # Try to get it from cache
  cached_parser = indexer.get_robots_parser("httpbin.org")
  puts "   ✓ Successfully retrieved robots parser from cache"

  puts "   ✓ Parser allows root: #{cached_parser.allowed?('https://httpbin.org/')}"
rescue StandardError => e
  puts "   ⚠ Error in full workflow: #{e.message}"
end

puts "\n🎉 Integrity testing complete!"
