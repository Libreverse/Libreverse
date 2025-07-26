#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test of AccountSequel methods

require_relative '../config/environment'

puts "Testing AccountSequel methods..."

# Get a sample account
account = AccountSequel.first

if account
  puts "Account: #{account.username}"
  puts "Guest?: #{account.guest?}"

  begin
    puts "Authenticated user?: #{account.authenticated_user?}"
    puts "Effective user?: #{account.effective_user?}"
    puts "Has guest role?: #{account.has_role?(:guest)}"
    puts "✅ Success! All methods are working."
  rescue StandardError => e
    puts "❌ Error: #{e.message}"
    puts "Stack trace: #{e.backtrace.first(3).join("\n")}"
  end
else
  puts "No accounts found to test."
end
