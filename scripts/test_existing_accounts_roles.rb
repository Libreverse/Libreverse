#!/usr/bin/env ruby
# frozen_string_literal: true

# Test role assignment for existing guest accounts

require_relative '../config/environment'
require_relative '../app/models/account'

puts "=== Testing Existing Guest Accounts ==="

# Find existing guest accounts
guest_accounts = Account.where(guest: true)

puts "Found #{guest_accounts.count} guest accounts:"

guest_accounts.each do |account|
  puts "\nAccount: #{account.username} (ID: #{account.id})"
  puts "  Roles: #{account.roles.pluck(:name)}"

  # Check if guest role is missing and assign it
  if account.has_role?(:guest)
    puts "  ✅ Guest role already assigned"
  else
    puts "  ⚠️  Missing guest role - assigning..."
    account.add_role(:guest)
    puts "  ✅ Guest role assigned"
  end

  # Test helper methods
  puts "  authenticated_user?: #{account.authenticated_user?}"
  puts "  effective_user?: #{account.effective_user?}"
  puts "  guest?: #{account.guest?}"
end

# Check user accounts too
puts "\n=== Testing Regular User Accounts ==="
user_accounts = Account.where(guest: false).limit(3)

user_accounts.each do |account|
  puts "\nAccount: #{account.username} (ID: #{account.id})"
  puts "  Roles: #{account.roles.pluck(:name)}"

  # Check if user role is missing and assign it
  if account.has_role?(:user)
    puts "  ✅ User role already assigned"
  else
    puts "  ⚠️  Missing user role - assigning..."
    account.add_role(:user)
    puts "  ✅ User role assigned"
  end

  # Test helper methods
  puts "  authenticated_user?: #{account.authenticated_user?}"
  puts "  effective_user?: #{account.effective_user?}"
  puts "  guest?: #{account.guest?}"
end

puts "\n=== Role Assignment Test Complete ==="
