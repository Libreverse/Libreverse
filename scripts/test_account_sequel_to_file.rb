#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the AccountSequel fix and save results to file

require_relative '../config/environment'

# Explicitly require the account model
require_relative '../app/models/account'

File.open('account_sequel_test_results.txt', 'w') do |file|
  file.puts "=== Testing AccountSequel Role Methods ==="
  file.puts "Time: #{Time.current}"
  file.puts

  # Test the methods work
  begin
    account = AccountSequel.first
    file.puts "AccountSequel class loaded successfully"
  rescue StandardError => e
    file.puts "Error loading AccountSequel: #{e.message}"
    file.puts "Trying to use Account.first instead..."
    account = Account.first
  end

  if account
    file.puts "Testing account: #{account.username}"
    file.puts "Account ID: #{account.id}"
    file.puts "Account class: #{account.class}"
    file.puts "Guest status: #{account.guest?}"
    file.puts

    # Test each method individually
    begin
      auth_status = account.authenticated_user?
      file.puts "✓ authenticated_user?: #{auth_status}"
    rescue StandardError => e
      file.puts "✗ authenticated_user? failed: #{e.message}"
      file.puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
    end

    begin
      effective_status = account.effective_user?
      file.puts "✓ effective_user?: #{effective_status}"
    rescue StandardError => e
      file.puts "✗ effective_user? failed: #{e.message}"
      file.puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
    end

    begin
      role_status = account.has_role?(:guest)
      file.puts "✓ has_role?(:guest): #{role_status}"
    rescue StandardError => e
      file.puts "✗ has_role? failed: #{e.message}"
      file.puts "  Backtrace: #{e.backtrace.first(3).join(', ')}"
    end

    file.puts
    file.puts "=== All methods tested! ==="
  else
    file.puts "No accounts found to test"
  end
end

puts "Test results saved to account_sequel_test_results.txt"
