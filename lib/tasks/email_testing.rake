# frozen_string_literal: true
# shareable_constant_value: literal

namespace :email do
  desc "Simulate sending email to search bot"
  task :test_search, [ :query ] => :environment do |_task, _args|
    query = ""
    sender_email = "test@example.com"
    sender_name = "Test User"

    puts "🔍 Simulating search email..."
    puts "From: #{sender_email}"
    puts "Query: #{query}"

    # Directly call the job (simulating mailbox processing)
    ProcessSearchEmailJob.perform_now(
      sender_email: sender_email,
      sender_name: sender_name,
      query: query,
      options: { federated: false, limit: 5 },
      original_message_id: "test-message-#{Time.current.to_i}"
    )

    puts "✅ Search email processed! Check MailHog at http://localhost:8025"
  end

  desc "Simulate sending email to experiences bot"
  task :test_experience, [ :title ] => :environment do |_task, args|
    title = args[:title] || "test experience"
    sender_email = "test@example.com"
    sender_name = "Test User"

    puts "📦 Simulating experience request email..."
    puts "From: #{sender_email}"
    puts "Experience: #{title}"

    # Directly call the job (simulating mailbox processing)
    ProcessExperienceEmailJob.perform_now(
      sender_email: sender_email,
      sender_name: sender_name,
      experience_title: title,
      original_message_id: "test-message-#{Time.current.to_i}"
    )

    puts "✅ Experience email processed! Check MailHog at http://localhost:8025"
  end

  desc "Process a real email (for testing with actual email files)"
  task :process_email, [ :email_file ] => :environment do |_task, args|
    email_file = args[:email_file]

    unless email_file && File.exist?(email_file)
      puts "❌ Email file not found: #{email_file}"
      puts "Usage: rails email:process_email[path/to/email.eml]"
      exit 1
    end

    puts "📧 Processing email file: #{email_file}"

    # Read and process the email through ActionMailbox
    email_content = File.read(email_file)
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(email_content)
    inbound_email.route

    puts "✅ Email processed! Check MailHog at http://localhost:8025"
  end

  desc "Create test experience for offline download"
  task create_test_experience: :environment do
    # Create a test experience that's offline-available
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Test Offline Experience</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          h1 { color: #333; }
          p { line-height: 1.6; }
        </style>
      </head>
      <body>
        <h1>Test Offline Experience</h1>
        <p>This is a test experience created for testing the email bot functionality.</p>
        <p>You can download this as a ZIP file by emailing experiences@#{LibreverseInstance.instance_domain}</p>
        <h2>Features</h2>
        <ul>
          <li>Offline reading capability</li>
          <li>Complete HTML with embedded styles</li>
          <li>Email-delivered ZIP file</li>
        </ul>
      </body>
      </html>
    HTML

    # Create a StringIO object to avoid writing decrypted data to disk
    html_io = StringIO.new(html_content)

    experience = Experience.new(
      title: "Test Offline Experience",
      description: "A test experience for trying out the email bot offline download functionality",
      author: "Email Bot Test",
      flags: 11  # approved(1) + federate(2) + offline_available(8) = 11
    )

    experience.html_file.attach(
      io: html_io,
      filename: "test_experience.html",
      content_type: "text/html"
    )

    if experience.save
      puts "✅ Test experience created successfully!"
      puts "   Title: #{experience.title}"
      puts "   ID: #{experience.id}"
      puts "   Offline Available: #{experience.offline_available}"
      puts ""
      puts "🧪 Now you can test with:"
      puts "   rails email:test_experience['Test Offline Experience']"
    else
      puts "❌ Failed to create test experience:"
      experience.errors.full_messages.each { |msg| puts "   #{msg}" }
    end

    temp_file.close
    temp_file.unlink
  end
end
