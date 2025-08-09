# frozen_string_literal: true

require "argon2"

puts "=== Testing Argon2 API ==="

# Test basic creation
begin
  argon2 = Argon2::Password.new
  password = "test123"
  hash = argon2.create(password)
  puts "✓ Hash created: #{hash[0..20]}..."

  # Test instance method verification
  begin
    result = argon2.verify_password(hash, password)
    puts "✓ Instance verify_password(hash, password): #{result}"
  rescue StandardError => e
    puts "✗ Instance verify_password(hash, password): #{e.message}"
  end

  # Test class method verification
  begin
    result = Argon2::Password.verify_password(password, hash)
    puts "✓ Class verify_password(password, hash): #{result}"
  rescue StandardError => e
    puts "✗ Class verify_password(password, hash): #{e.message}"
  end

  # Test with wrong password
  begin
    result = argon2.verify_password(hash, "wrong")
    puts "✓ Wrong password verification: #{result}"
  rescue StandardError => e
    puts "✗ Wrong password verification: #{e.message}"
  end
rescue StandardError => e
  puts "✗ Basic creation failed: #{e.message}"
end

puts "=== API Discovery ==="
puts "Argon2 constants: #{Argon2.constants}"
puts "Argon2::Password instance methods: #{Argon2::Password.instance_methods.grep(/verify|create/)}"
puts "Argon2::Password class methods: #{Argon2::Password.methods.grep(/verify|create/)}"
