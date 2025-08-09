#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Argon2 API

puts "Testing Argon2 API..."

# Test hash creation and verification
a = Argon2::Password.new
password = 'test'
h = a.create(password)
puts "Hash: #{h}"

# Test class-level verification with different argument orders
puts "\nTesting verification..."

begin
  result = Argon2::Password.verify_password(password, h)
  puts "verify_password(password, hash) works: #{result}"
rescue StandardError => e
  puts "verify_password(password, hash) failed: #{e.message}"
end

begin
  result = Argon2::Password.verify_password(h, password)
  puts "verify_password(hash, password) works: #{result}"
rescue StandardError => e
  puts "verify_password(hash, password) failed: #{e.message}"
end

# Test wrong password
begin
  result = Argon2::Password.verify_password('wrong', h)
  puts "Wrong password result: #{result}"
rescue StandardError => e
  puts "Wrong password failed: #{e.message}"
end
