#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the AccountSequel has_role? fix

require_relative '../config/environment'

# Explicitly require the model
require_relative '../app/models/account'

puts "=== Testing AccountSequel has_role? Fix ==="

# Test the methods work
account = AccountSequel.first

if account
  puts "Testing account: #{account.username} (ID: #{account.id})"
  
  begin
    # Test has_role? method
    guest_role = account.has_role?(:guest)
    puts "✓ has_role?(:guest): #{guest_role}"
    
    user_role = account.has_role?(:user)  
    puts "✓ has_role?(:user): #{user_role}"
    
    admin_role = account.has_role?(:admin)
    puts "✓ has_role?(:admin): #{admin_role}"
    
    # Test that Ability class can now work
    puts "\n=== Testing Ability Class ==="
    ability = Ability.new(account)
    puts "✓ Ability class created successfully!"
    
    # Test some permissions
    puts "  - Can read Experience: #{ability.can?(:read, Experience)}"
    puts "  - Can create Experience: #{ability.can?(:create, Experience)}"
    puts "  - Can access dashboard: #{ability.can?(:access, :dashboard)}"
    
  rescue StandardError => e
    puts "✗ Error: #{e.message}"
    puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
  end
else
  puts "No accounts found to test"
end

puts "\n=== Test Complete ==="
