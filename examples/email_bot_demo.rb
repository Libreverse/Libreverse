#!/usr/bin/env ruby

# Demo script for testing Libreverse email automation
# This script demonstrates the email bot functionality

puts <<~BANNER
  🤖 Libreverse Email Bot Demo
  ============================

  This script demonstrates how to interact with the Libreverse email system
  to automatically search for experiences and request downloadable files.

  The Libreverse app accepts emails at:
  • search@your-domain.com    - for searching experiences
  • experiences@your-domain.com - for requesting downloadable experience files

BANNER

puts "Select an action:"
puts "1. 🚀 Search for space-related experiences"
puts "2. 🧘 Request Meditation and Mindfulness Space experience"
puts "3. 🤖 Run both actions automatically"
puts "4. 🔍 Custom search"
puts "5. 📄 Custom experience request"
puts "6. ℹ️  Show help"
puts "0. Exit"
print "\nChoice: "

choice = gets.chomp

case choice
when '1'
  puts "\n🚀 Space Search Demo"
  puts "This will send an email to search@your-domain.com with query 'space exploration'"
  puts "Example email content:"
  puts <<~EMAIL
    From: demo@example.com
    To: search@your-domain.com
    Subject: space exploration

    space exploration

    --federated: false
    --limit: 10
    --format: links
  EMAIL

when '2'
  puts "\n🧘 Meditation Experience Request Demo"
  puts "This will send an email to experiences@your-domain.com requesting the meditation experience"
  puts "Example email content:"
  puts <<~EMAIL
    From: demo@example.com
    To: experiences@your-domain.com
    Subject: Meditation and Mindfulness Space

    Meditation and Mindfulness Space

    ---
    Please send the offline version of this experience.
  EMAIL

when '3'
  puts "\n🤖 Full Automation Demo"
  puts "This would send both emails in sequence."
  puts "Perfect for testing the complete email workflow!"

when '4'
  print "\n🔍 Enter your search query: "
  query = gets.chomp
  puts "\nThis would search for: '#{query}'"
  puts "Email would be sent to: search@your-domain.com"

when '5'
  print "\n📄 Enter experience title: "
  title = gets.chomp
  puts "\nThis would request: '#{title}'"
  puts "Email would be sent to: experiences@your-domain.com"

when '6'
  puts <<~HELP

    📖 How to Use the Email Bot:

    SETUP:
    1. Ensure your Libreverse instance is running
    2. Configure email delivery in your Rails app
    3. Enable the email bot in instance settings

    SEARCH EMAILS (search@your-domain.com):
    • Subject: Your search query
    • Body: Search terms and optional commands:
      --federated: true/false (search across federated instances)
      --limit: number (max results, up to 100)
      --format: links/attachment (response format)

    EXPERIENCE REQUESTS (experiences@your-domain.com):
    • Subject: Experience title
    • Body: Experience title you want to download
    • Must be marked as "offline available" by the creator

    RAILS TASKS:
    You can also run these from the Rails console:
    • rails email_bot:space_search
    • rails email_bot:meditation_request
    • rails email_bot:both
    • rails email_bot:search['your query']
    • rails email_bot:experience['experience title']
    • rails email_bot:status

    RUBY SCRIPT:
    Use the email_automation_script.rb:
    • ruby scripts/email_automation_script.rb auto
    • ruby scripts/email_automation_script.rb search "your query"
    • ruby scripts/email_automation_script.rb experience "title"

  HELP

when '0'
  puts "👋 Goodbye!"
  exit

else
  puts "❌ Invalid choice. Please run the script again."
  exit 1
end

puts "\n#{'=' * 50}"
puts "📝 Next Steps:"
puts "1. Set up your email configuration"
puts "2. Run: rails email_bot:both    (to test both functions)"
puts "3. Check your email for responses"
puts "4. Monitor Rails logs for processing details"
puts "=" * 50
