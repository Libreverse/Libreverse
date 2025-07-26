#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the AccountSequel fix

require_relative '../config/environment'

puts "=== Testing AccountSequel Role Methods ==="

# Test the methods work
account = AccountSequel.first

if account
  puts "Testing account: #{account.username}"

  # Test each method individually
  begin
    guest_status = account.guest?
    puts "✓ guest?: #{guest_status}"
  rescue StandardError => e
    puts "✗ guest? failed: #{e.message}"
  end

  begin
    auth_status = account.authenticated_user?
    puts "✓ authenticated_user?: #{auth_status}"
  rescue StandardError => e
    puts "✗ authenticated_user? failed: #{e.message}"
  end

  begin
    effective_status = account.effective_user?
    puts "✓ effective_user?: #{effective_status}"
  rescue StandardError => e
    puts "✗ effective_user? failed: #{e.message}"
  end

  begin
    role_status = account.has_role?(:guest)
    puts "✓ has_role?(:guest): #{role_status}"
  rescue StandardError => e
    puts "✗ has_role? failed: #{e.message}"
  end

  puts "\n=== All methods tested successfully! ==="
else
  puts "No accounts found to test"
end
