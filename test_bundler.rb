# frozen_string_literal: true

# Minimal test to isolate Bundler.require hang
require 'bundler/setup'
puts "Testing minimal Bundler.require..."

# Test requiring Rails first
puts "Requiring rails/all..."
require "rails/all"
puts "rails/all loaded"

# Test Bundler.require with just default group
puts "Calling Bundler.require with default group..."
start_time = Time.now
Bundler.require(:default)
duration = Time.now - start_time
puts "Bundler.require(:default) completed in #{duration.round(2)}s"

puts "Test completed successfully"
