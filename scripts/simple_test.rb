#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test

puts "Starting test..."

begin
  # Make the methods public for testing
  class TestIndexer < BaseIndexer
    public :generate_cache_integrity_hash, :verify_cache_integrity
  end

  puts "TestIndexer class created"

  indexer = TestIndexer.new
  puts "Indexer instance created"

  test_data = "sample_data"
  test_domain = "example.com"

  puts "Generating hash..."
  hash = indexer.generate_cache_integrity_hash(test_data, test_domain)
  puts "Hash: #{hash[0..30]}..."

  puts "Verifying..."
  result = indexer.verify_cache_integrity(test_data, test_domain, hash)
  puts "Verification result: #{result}"
rescue StandardError => e
  puts "Error: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
end

puts "Test complete."
