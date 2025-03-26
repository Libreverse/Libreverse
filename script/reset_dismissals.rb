#!/usr/bin/env ruby
# frozen_string_literal: true

# This script resets all dismissal preferences in the application
# Run with: rails runner script/reset_dismissals.rb

# Delete all dismissal preferences from the database
count = UserPreference.where(value: "dismissed").destroy_all.count

# Clear dismissal session data as well
session_count = 0
ActiveRecord::SessionStore::Session.find_each do |session_record|
  # Parse session data safely
  begin
    session_data = session_record.data
    if session_data && session_data["dismissed_items"].present?
      # Clear dismissal items and save the session
      session_data.delete("dismissed_items")
      session_record.save
      session_count += 1
    end
  rescue => e
    puts "Error processing session #{session_record.id}: #{e.message}"
  end
end

puts "✅ Reset complete:"
puts "  - #{count} dismissal preferences deleted from the database"
puts "  - #{session_count} sessions cleared of dismissal data"
puts 
puts "Note: For a complete reset, you should also:"
puts "  - Restart your Rails server to clear in-memory sessions"
puts "  - Clear your browser cookies"
puts
puts "To test the new dismissible implementation:"
puts "  1. Refresh your browser to see previously dismissed items again"
puts "  2. Try dismissing items to verify the functionality" 