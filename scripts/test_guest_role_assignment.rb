#!/usr/bin/env ruby
# frozen_string_literal: true

# Test guest account role assignment

require_relative '../config/environment'
require_relative '../app/models/account'

puts "=== Testing Guest Account Role Assignment ==="

# Create a test guest account the same way Rodauth does
puts "Creating guest account..."

# Simulate what happens in Rodauth's before_create_guest hook
guest_login = SecureRandom.uuid
guest_account = AccountSequel.create(
  username: guest_login,
  guest: true,
  status: 2,
  created_at: Time.current,
  updated_at: Time.current
)

puts "Created guest account: #{guest_account.username} (ID: #{guest_account.id})"

# Test role assignment via ActiveRecord bridge
ar_account = Account.find_by(id: guest_account.id)

if ar_account
  puts "Found ActiveRecord account: #{ar_account.username}"

  # Test current roles
  puts "Current roles: #{ar_account.roles.pluck(:name)}"

  # Assign guest role
  ar_account.add_role(:guest) unless ar_account.has_role?(:guest)

  # Test again
  puts "Roles after assignment: #{ar_account.roles.pluck(:name)}"

  # Test our helper methods
  puts "guest?: #{ar_account.guest?}"
  puts "has_role?(:guest): #{ar_account.has_role?(:guest)}"
  puts "authenticated_user?: #{ar_account.authenticated_user?}"
  puts "effective_user?: #{ar_account.effective_user?}"
else
  puts "ERROR: Could not find ActiveRecord account!"
end

# Test AccountSequel methods too
puts "\nTesting AccountSequel methods:"
puts "guest?: #{guest_account.guest?}"
puts "has_role?(:guest): #{guest_account.has_role?(:guest)}"
puts "authenticated_user?: #{guest_account.authenticated_user?}"
puts "effective_user?: #{guest_account.effective_user?}"

puts "\n=== Test Complete ==="
