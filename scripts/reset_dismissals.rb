# typed: false
#!/usr/bin/env ruby
# frozen_string_literal: true
# shareable_constant_value: literal

# This script resets all dismissal preferences in the application
# Run with: rails runner script/reset_dismissals.rb

# Delete all dismissal preferences from the database
count = UserPreference.where(value: "dismissed").destroy_all.count

puts "✅ Reset complete: #{count} dismissal preferences deleted from the database."
puts
puts "Note: Session-based dismissals will be automatically cleared when:"
puts "  - You restart your web server"
puts "  - You clear your browser cookies"
puts "  - Sessions expire naturally"
puts
puts "To test the new dismissible implementation:"
puts "  1. Restart your Rails server to clear sessions"
puts "  2. Refresh your browser to see previously dismissed items again"
