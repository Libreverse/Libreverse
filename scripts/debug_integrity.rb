#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../app/indexers/base_indexer'

class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

puts "=== Debugging Argon2 Integrity Checking ==="

indexer = TestIndexer.new
data = 'test_data'
domain = 'example.com'

puts "1. Test data: #{data}"
puts "2. Domain: #{domain}"
puts

# Generate derived key
key_generator = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base,
  iterations: 1000
)
pepper = key_generator.generate_key("robots_cache_integrity", 32)
puts "3. Pepper (first 10 bytes): #{pepper[0..9].unpack1('H*')}"

# Create input for hashing
input = "#{data}#{pepper}"
puts "4. Input length: #{input.length}"
puts "5. Input (first 20 chars): #{input[0..19]}"
puts

# Generate hash
puts "6. Generating hash..."
hash = indexer.generate_cache_integrity_hash(data, domain)
puts "7. Generated hash: #{hash}"
puts

# Now test verification step by step
puts "8. Testing verification..."

# Recreate the same input in verification
key_generator2 = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base,
  iterations: 1000
)
pepper2 = key_generator2.generate_key("robots_cache_integrity", 32)
input2 = "#{data}#{pepper2}"

puts "9. Verification pepper matches: #{pepper == pepper2}"
puts "10. Verification input matches: #{input == input2}"
puts

# Test direct Argon2 verification
puts "11. Direct Argon2 verification:"
begin
  result = Argon2::Password.verify_password(input2, hash)
  puts "    Result: #{result}"
rescue StandardError => e
  puts "    Error: #{e.message}"
end
puts

# Test our method
puts "12. Our verification method:"
result = indexer.verify_cache_integrity(data, domain, hash)
puts "    Result: #{result}"

puts "\n=== Test Complete ==="
