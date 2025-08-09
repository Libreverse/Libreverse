#!/usr/bin/env ruby
# frozen_string_literal: true

puts "=== Testing Argon2.hash_pwd_salt method ==="

begin
  # Test basic Argon2 functionality
  result = Argon2.hash_pwd_salt(
    "test_password",
    "testsalt1234567", # 16 chars
    1,    # t_cost
    12,   # m_cost (2^12 = 4096 KB)
    1,    # p_cost
    32    # output length
  )
  puts "Success! Hash: #{result[0..30]}..."
rescue StandardError => e
  puts "Error: #{e.class}: #{e.message}"
  puts "Available methods: #{Argon2.methods.sort}"
end
