# frozen_string_literal: true

# Configure Federails moderation for handling reports about federated content
Federails::Moderation.configure do |conf|
  # Handle incoming reports about experiences
  conf.after_report_created = lambda { |report|
    LibreverseReportHandler.new(report).process
  }
end
