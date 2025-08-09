#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the fixed integrity checking
class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

puts "=== Testing Fixed Argon2 Integrity Checking ==="

indexer = TestIndexer.new
data = "test_marshaled_data"
domain = "example.com"

puts "1. Data: #{data}"
puts "2. Domain: #{domain}"

puts "\n3. Generating hash..."
hash1 = indexer.generate_cache_integrity_hash(data, domain)
puts "   Hash: #{hash1[0..20]}..."

puts "\n4. Generating same hash again (should be identical)..."
hash2 = indexer.generate_cache_integrity_hash(data, domain)
puts "   Hash: #{hash2[0..20]}..."
puts "   Hashes match: #{hash1 == hash2}"

puts "\n5. Verifying with correct data..."
result1 = indexer.verify_cache_integrity(data, domain, hash1)
puts "   Verification: #{result1}"

puts "\n6. Verifying with wrong data..."
result2 = indexer.verify_cache_integrity("wrong_data", domain, hash1)
puts "   Verification: #{result2}"

puts "\n7. Verifying with wrong domain..."
result3 = indexer.verify_cache_integrity(data, "wrong.com", hash1)
puts "   Verification: #{result3}"

puts "\n=== Test Results ==="
puts "✓ Deterministic: #{hash1 == hash2}"
puts "✓ Correct verification: #{result1}"
puts "✓ Rejects wrong data: #{!result2}"
puts "✓ Rejects wrong domain: #{!result3}"

if hash1 == hash2 && result1 && !result2 && !result3
  puts "\n🎉 ALL TESTS PASSED! Integrity checking works perfectly!"
else
  puts "\n❌ Some tests failed!"
end
