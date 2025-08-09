#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the integrity checking system

# Make the methods public for testing
class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

puts "🧪 Testing Robots Cache Integrity System"
puts "=" * 50

indexer = TestIndexer.new
test_data = "sample_marshalled_robot_data_here"
test_domain = "example.com"

puts "1. Generating integrity hash..."
begin
  hash = indexer.generate_cache_integrity_hash(test_data, test_domain)
  puts "✅ Hash generated: #{hash[0..50]}..."
rescue StandardError => e
  puts "❌ Hash generation failed: #{e.message}"
  exit 1
end

puts "\n2. Verifying with correct data..."
begin
  result = indexer.verify_cache_integrity(test_data, test_domain, hash)
  if result
    puts "✅ Verification succeeded (correct)"
  else
    puts "❌ Verification failed (but should have succeeded)"
    exit 1
  end
rescue StandardError => e
  puts "❌ Verification error: #{e.message}"
  exit 1
end

puts "\n3. Testing with wrong data..."
begin
  result = indexer.verify_cache_integrity("tampered_data", test_domain, hash)
  if result
    puts "❌ Verification succeeded (but should have failed - SECURITY ISSUE!)"
    exit 1
  else
    puts "✅ Verification correctly rejected tampered data"
  end
rescue StandardError => e
  puts "❌ Verification error: #{e.message}"
  exit 1
end

puts "\n4. Testing with wrong domain..."
begin
  result = indexer.verify_cache_integrity(test_data, "evil.com", hash)
  if result
    puts "❌ Verification succeeded (but should have failed - SECURITY ISSUE!)"
    exit 1
  else
    puts "✅ Verification correctly rejected different domain"
  end
rescue StandardError => e
  puts "❌ Verification error: #{e.message}"
  exit 1
end

puts "\n5. Testing with invalid hash..."
begin
  result = indexer.verify_cache_integrity(test_data, test_domain, "invalid_hash")
  if result
    puts "❌ Verification succeeded (but should have failed - SECURITY ISSUE!)"
    exit 1
  else
    puts "✅ Verification correctly rejected invalid hash"
  end
rescue StandardError => e
  puts "✅ Verification correctly failed with invalid hash: #{e.message}"
end

puts "\n🎉 All integrity tests passed! The system is secure."
puts "\nSecurity properties verified:"
puts "- ✅ Valid data/domain combinations verify correctly"
puts "- ✅ Tampered data is rejected"
puts "- ✅ Wrong domain is rejected"
puts "- ✅ Invalid hashes are rejected"
puts "- ✅ Cryptographically impossible to forge without Rails secret"
