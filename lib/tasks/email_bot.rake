# frozen_string_literal: true

namespace :email_bot do
  desc "Send a search email for space-related experiences"
  task space_search: :environment do
    puts "🚀 Sending search email for space-related experiences..."

    # Create a test email and process it through ActionMailbox
    raw_email = build_search_email(
      from: "automation@#{LibreverseInstance.instance_domain}",
      to: "search@#{LibreverseInstance.instance_domain}",
      subject: "space exploration",
      body: "space exploration\n\n--federated: false\n--limit: 10\n--format: links"
    )

    # Process through ActionMailbox
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
    puts "✅ Email processed with ID: #{inbound_email.id}"
    puts "📧 Search for 'space exploration' has been queued for processing"
  end

  desc "Send a request email for Meditation and Mindfulness Space experience"
  task meditation_request: :environment do
    puts "🧘 Sending request for Meditation and Mindfulness Space experience..."

    # Create a test email and process it through ActionMailbox
    raw_email = build_experience_request_email(
      from: "automation@#{LibreverseInstance.instance_domain}",
      to: "experiences@#{LibreverseInstance.instance_domain}",
      subject: "Meditation and Mindfulness Space",
      body: "Meditation and Mindfulness Space\n\n---\nAutomated experience request\nPlease send the offline version of this experience."
    )

    # Process through ActionMailbox
    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
    puts "✅ Email processed with ID: #{inbound_email.id}"
    puts "📧 Request for 'Meditation and Mindfulness Space' has been queued for processing"
  end

  desc "Send both space search and meditation request emails"
  task both: :environment do
    puts "🤖 Running full email automation sequence..."
    puts "=" * 60

    # Ensure example experiences exist
    if Experience.where(title: "Meditation and Mindfulness Space").empty?
      puts "📝 Creating example experiences first..."
      ExampleExperiencesService.new.add_examples
      puts "✅ Example experiences created"
    end

    # Send space search
    Rake::Task["email_bot:space_search"].invoke

    puts
    puts "⏱️  Waiting 3 seconds between emails..."
    sleep(3)

    # Send meditation request
    Rake::Task["email_bot:meditation_request"].invoke

    puts "=" * 60
    puts "✅ Email automation sequence completed!"
    puts "📬 Check your configured email delivery method for responses."
    puts "💡 You can also check the Rails logs to see email processing in action."
  end

  desc "Send a custom search email"
  task :search, [ :query ] => :environment do |_t, args|
    query = args[:query]
    if query.blank?
      puts "❌ Please provide a search query"
      puts "Usage: rails email_bot:search['your search query']"
      exit 1
    end

    puts "🔍 Sending search email for '#{query}'..."

    raw_email = build_search_email(
      from: "automation@#{LibreverseInstance.instance_domain}",
      to: "search@#{LibreverseInstance.instance_domain}",
      subject: query,
      body: "#{query}\n\n--federated: false\n--limit: 20\n--format: links"
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
    puts "✅ Email processed with ID: #{inbound_email.id}"
    puts "📧 Search for '#{query}' has been queued for processing"
  end

  desc "Send a custom experience request email"
  task :experience, [ :title ] => :environment do |_t, args|
    title = args[:title]
    if title.blank?
      puts "❌ Please provide an experience title"
      puts "Usage: rails email_bot:experience['Experience Title']"
      exit 1
    end

    puts "📄 Sending experience request for '#{title}'..."

    raw_email = build_experience_request_email(
      from: "automation@#{LibreverseInstance.instance_domain}",
      to: "experiences@#{LibreverseInstance.instance_domain}",
      subject: title,
      body: "#{title}\n\n---\nAutomated experience request\nPlease send the offline version of this experience."
    )

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
    puts "✅ Email processed with ID: #{inbound_email.id}"
    puts "📧 Request for '#{title}' has been queued for processing"
  end

  desc "Show email bot status and configuration"
  task status: :environment do
    puts "🤖 Email Bot Status"
    puts "=" * 40
    puts "Email Bot Enabled: #{LibreverseInstance.email_bot_enabled? ? '✅ Yes' : '❌ No'}"
    puts "Instance Domain: #{LibreverseInstance.instance_domain}"
    puts "Search Email: search@#{LibreverseInstance.instance_domain}"
    puts "Experience Email: experiences@#{LibreverseInstance.instance_domain}"
    puts
    puts "📊 Email Statistics:"
    puts "  Total Inbound Emails: #{ActionMailbox::InboundEmail.count}"

    # Show recent jobs from Solid Queue if available
    begin
      if defined?(SolidQueue::Job)
        search_jobs = SolidQueue::Job.where(class_name: "ProcessSearchEmailJob").count
        experience_jobs = SolidQueue::Job.where(class_name: "ProcessExperienceEmailJob").count
        puts "  Search Jobs (all time): #{search_jobs}"
        puts "  Experience Jobs (all time): #{experience_jobs}"
      else
        puts "  Job queue information not available"
      end
    rescue StandardError => e
      puts "  Job queue information not available (#{e.class})"
    end
    puts
    puts "🎯 Available Experiences:"
    approved_experiences = Experience.approved.limit(5)
    if approved_experiences.any?
      approved_experiences.each do |exp|
        offline_status = exp.offline_available? ? "📦 Offline" : "🌐 Online Only"
        puts "  • #{exp.title} (#{offline_status})"
      end
      puts "  ... and #{Experience.approved.count - 5} more" if Experience.approved.count > 5
    else
      puts "  No approved experiences found"
    end
  end

  desc "Test email processing directly (bypasses email bot enabled check)"
  task test_direct: :environment do
    puts "🧪 Testing email processing directly..."
    puts "This will process emails directly without checking if the bot is enabled."
    puts

    # Test search email
    puts "1. Testing search email processing..."
    begin
      ProcessSearchEmailJob.perform_now(
        sender_email: "test@example.com",
        sender_name: "Test User",
        query: "space exploration",
        options: { federated: false, limit: 10, format: :links },
        original_message_id: "<test-#{SecureRandom.uuid}@test>"
      )
      puts "✅ Search email processed successfully"
    rescue StandardError => e
      puts "❌ Search email failed: #{e.message}"
    end

    puts

    # Test experience request (if meditation experience exists)
    puts "2. Testing experience request processing..."
    begin
      ProcessExperienceEmailJob.perform_now(
        sender_email: "test@example.com",
        sender_name: "Test User",
        experience_title: "Meditation and Mindfulness Space",
        original_message_id: "<test-#{SecureRandom.uuid}@test>"
      )
      puts "✅ Experience request processed successfully"
    rescue StandardError => e
      puts "❌ Experience request failed: #{e.message}"
    end

    puts
    puts "📬 Check your email delivery logs to see if emails were sent."
  end

  private

  def build_search_email(from:, to:, subject:, body:)
    <<~EMAIL
      From: #{from}
      To: #{to}
      Subject: #{subject}
      Date: #{Time.current.rfc2822}
      Message-ID: <#{SecureRandom.uuid}@#{LibreverseInstance.instance_domain}>
      Content-Type: text/plain; charset=UTF-8

      #{body}
    EMAIL
  end

  def build_experience_request_email(from:, to:, subject:, body:)
    <<~EMAIL
      From: #{from}
      To: #{to}
      Subject: #{subject}
      Date: #{Time.current.rfc2822}
      Message-ID: <#{SecureRandom.uuid}@#{LibreverseInstance.instance_domain}>
      Content-Type: text/plain; charset=UTF-8

      #{body}
    EMAIL
  end
end
