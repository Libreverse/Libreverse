#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick manual test for robots cache integrity
# Run with: bin/rails runner scripts/manual_test_integrity.rb

puts "🧪 Manual Robots Cache Integrity Test"
puts "=" * 40

# Create test indexer
class QuickTestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

indexer = QuickTestIndexer.new

# Test data
test_domain = "manual-test.example.com"
test_data = "test_robots_parser_data_#{Time.current.to_i}"

puts "1. Generating integrity hash..."
hash = indexer.generate_cache_integrity_hash(test_data, test_domain)
puts "   Hash: #{hash[0..50]}..."
puts "   ✅ Generated successfully"

puts "\n2. Verifying with correct data..."
verified = indexer.verify_cache_integrity(test_data, test_domain, hash)
puts "   Result: #{verified}"
puts verified ? "   ✅ Verification passed" : "   ❌ Verification failed"

puts "\n3. Testing tampering detection..."
tampered_data = "#{test_data}_TAMPERED"
tampered_result = indexer.verify_cache_integrity(tampered_data, test_domain, hash)
puts "   Tampered verification: #{tampered_result}"
puts tampered_result ? "   ❌ Should have failed!" : "   ✅ Correctly detected tampering"

puts "\n4. Testing different domain..."
different_domain = "different.example.com"
cross_domain_result = indexer.verify_cache_integrity(test_data, different_domain, hash)
puts "   Cross-domain verification: #{cross_domain_result}"
puts cross_domain_result ? "   ❌ Should have failed!" : "   ✅ Correctly rejected cross-domain"

puts "\n5. Testing cache integration..."
cache_key = "test_robots_parser_#{test_domain}"
cache_entry = {
  data: test_data,
  integrity_hash: hash,
  created_at: Time.current.iso8601,
  domain: test_domain
}

Rails.cache.write(cache_key, cache_entry, expires_in: 1.hour)
retrieved = Rails.cache.read(cache_key)

if retrieved.is_a?(Hash)
  puts "   Cache write/read: ✅"
  cache_verified = indexer.verify_cache_integrity(retrieved[:data], test_domain, retrieved[:integrity_hash])
  puts "   Cache verification: #{cache_verified ? '✅' : '❌'}"
else
  puts "   Cache write/read: ❌"
end

puts "\n6. Performance test..."
start_time = Time.zone.now
100.times do |i|
  test_hash = indexer.generate_cache_integrity_hash("test_data_#{i}", "domain#{i}.com")
  indexer.verify_cache_integrity("test_data_#{i}", "domain#{i}.com", test_hash)
end
total_time = Time.zone.now - start_time
puts "   100 hash/verify cycles: #{(total_time * 1000).round(2)}ms"
puts "   Average per cycle: #{(total_time * 10).round(2)}ms"

puts "\n#{'=' * 40}"
puts "🎯 Manual test complete!"
puts "\nTo test with real robots parser:"
puts "   rails runner -e development scripts/test_robots_cache_live.rb"
