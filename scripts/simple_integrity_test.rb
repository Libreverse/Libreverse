#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test for integrity checking
class TestIndexer < BaseIndexer
  public :generate_cache_integrity_hash, :verify_cache_integrity
end

puts "Testing integrity checking..."

indexer = TestIndexer.new
data = "test_data"
domain = "example.com"

puts "Generating hash..."
hash = indexer.generate_cache_integrity_hash(data, domain)
puts "Hash: #{hash[0..20]}..."

puts "Verifying correct data..."
result1 = indexer.verify_cache_integrity(data, domain, hash)
puts "Result: #{result1}"

puts "Verifying wrong data..."
result2 = indexer.verify_cache_integrity("wrong", domain, hash)
puts "Result: #{result2}"

puts "Success!" if result1 && !result2
