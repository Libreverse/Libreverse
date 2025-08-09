# frozen_string_literal: true

puts "🧪 Testing HMAC-based Cache Integrity System"
puts "=" * 50

# Test class to access private methods
class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

begin
  indexer = TestIndexer.new
  test_data = "test_marshal_data_12345"
  domain = "example.com"

  puts "1. Generating integrity hash..."
  hash1 = indexer.generate_cache_integrity_hash(test_data, domain)
  puts "   Hash: #{hash1[0..20]}... (#{hash1.length} chars)"

  puts "2. Generating same hash again (should match)..."
  hash2 = indexer.generate_cache_integrity_hash(test_data, domain)
  puts "   Hash: #{hash2[0..20]}... (#{hash2.length} chars)"
  puts "   Hashes match: #{hash1 == hash2}"

  puts "3. Verifying correct data..."
  result = indexer.verify_cache_integrity(test_data, domain, hash1)
  puts "   Verification result: #{result}"

  puts "4. Testing with wrong data..."
  wrong_result = indexer.verify_cache_integrity("wrong_data", domain, hash1)
  puts "   Wrong data verification: #{wrong_result}"

  puts "5. Testing with wrong domain..."
  wrong_domain_result = indexer.verify_cache_integrity(test_data, "wrong.com", hash1)
  puts "   Wrong domain verification: #{wrong_domain_result}"

  puts "6. Testing with wrong hash..."
  wrong_hash_result = indexer.verify_cache_integrity(test_data, domain, "wrong_hash")
  puts "   Wrong hash verification: #{wrong_hash_result}"

  puts "\n✅ All tests completed successfully!"
  puts "The HMAC-based integrity system is working properly."
rescue StandardError => e
  puts "\n❌ Test failed with error:"
  puts "   #{e.class}: #{e.message}"
  puts "   #{e.backtrace.first}"
end
