# frozen_string_literal: true

# Configure Federails moderation for handling reports about federated content
Federails::Moderation.configure do |conf|
  # Handle incoming reports about experiences
  conf.after_report_created = lambda do |report|
    LibreverseReportHandler.new(report).process
  rescue StandardError => e
    Rails.logger.error("LibreverseReportHandler failed: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    # Optionally enqueue a retry job instead of aborting the request thread
    # Libreverse::ReportHandlerJob.perform_later(report.id)
  end
end
