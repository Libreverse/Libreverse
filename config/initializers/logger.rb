# frozen_string_literal: true

# Application-wide Logging Configuration
# This initializer ensures consistent logging across the application
# by configuring the Rails logger and all related loggers properly.

# Create a custom formatter that preserves TaggedLogging functionality
module CustomTaggedFormatter
    COLORS = {
      reset: "\033[0m",
      bold: "\033[1m",
      red: "\033[38;5;174m",
      green: "\033[38;5;150m",
      yellow: "\033[38;5;150m",
      blue: "\033[38;5;182m",
      magenta: "\033[38;5;182m",
      cyan: "\033[38;5;115m",
      light_blue: "\033[38;5;182m",
      light_cyan: "\033[38;5;115m",
      light_gray: "\033[38;5;224m",
      dark_gray: "\033[38;5;110m"
    }.freeze

  # Get color for severity level
  def color_for_severity(severity)
    case severity
    when "DEBUG" then COLORS[:dark_gray]
    when "INFO" then COLORS[:green]
    when "WARN" then COLORS[:yellow]
    when "ERROR" then COLORS[:red]
    when "FATAL" then "#{COLORS[:bold]}#{COLORS[:red]}"
    else COLORS[:light_gray]
    end
  end

  def call(severity, timestamp, _progname, msg)
    message_string = msg.to_s

    # Silence specific SolidCable DEBUG messages
    return nil if severity == "DEBUG" && message_string.include?("SolidCable::Message Insert")

    message = if defined?(LogFormatting)
      LogFormatting.truncate(message_string)
    else
      message_string
    end

    # Always use colors in development, regardless of TTY
    use_colors = Rails.env.development?

    time_format = timestamp.strftime("%Y-%m-%d %H:%M:%S.%L")
    request_id = Thread.current[:request_id] || "no_request_id"
    tags_text = current_tags.any? ? "#{current_tags.join(',')} " : ""

    if use_colors
      # Colorized version
      timestamp_colored = "#{COLORS[:cyan]}[#{time_format}]#{COLORS[:reset]}"
      severity_colored = "#{color_for_severity(severity)}[#{severity}]#{COLORS[:reset]}"
      request_id_colored = "#{COLORS[:light_blue]}[#{request_id}]#{COLORS[:reset]}"
      tags_colored = current_tags.any? ? "#{COLORS[:magenta]}#{tags_text}#{COLORS[:reset]}" : ""

      "#{timestamp_colored} #{severity_colored} #{request_id_colored} #{tags_colored}#{message}\n"
    else
      # Plain version (for production or non-TTY output)
      "[#{time_format}] [#{severity}] [#{request_id}] #{tags_text}#{message}\n"
    end
  end
end

# Configure the Rails logger to use our custom tagged formatter
# We need to rebuild the logger to ensure it has all the required functionality
require "active_support/logger"

# Create an ActiveSupport::Logger (not the standard Ruby Logger)
# which automatically includes the silence method needed by ActiveRecord session store
# In containers, write logs to STDOUT so the orchestrator captures them.
io_target = if Rails.env.production?
  $stdout
else
  Rails.root.join("log", "#{Rails.env}.log")
end

logger = ActiveSupport::Logger.new(io_target)

# Ensure it has the LoggerSilencer module included (needed for the 'silence' method)
logger.extend(ActiveSupport::LoggerSilencer) unless logger.respond_to?(:silence)

# Add tagging functionality and our custom formatter
logger = ActiveSupport::TaggedLogging.new(logger)
logger.formatter.extend(CustomTaggedFormatter)

# Replace the Rails logger
Rails.logger = logger

# Ensure the application config uses the same logger instance
Rails.application.config.logger = Rails.logger

# Configure log levels based on environment
if Rails.env.development?
  Rails.logger.level = Logger::DEBUG
elsif Rails.env.test?
  # In test environment, use ERROR level by default to minimize noise
  # The log capture system in test_helper.rb will show logs for failed tests
  Rails.logger.level = Logger::ERROR
else
  # In production, log as verbosely as development by default (override via RAILS_LOG_LEVEL)
  level_str = ENV.fetch("RAILS_LOG_LEVEL") { "debug" }
  Rails.logger.level = Logger.const_get(level_str.upcase)
end

# Force colorization in development
ActiveSupport::LogSubscriber.colorize_logging = true if Rails.env.development?

# Ensure ActionCable uses the same logger as Rails
ActionCable.server.config.logger = Rails.logger

# Ensure ActiveJob uses the same logger as Rails
ActiveJob::Base.logger = Rails.logger

# Ensure Active Record, Action Controller, and other loggers use Rails logger
ActiveRecord::Base.logger = Rails.logger
ActionController::Base.logger = Rails.logger
ActionView::Base.logger = Rails.logger

# Middleware to set request_id for logging context
class RequestIdMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = env["action_dispatch.request_id"]
    # Ensure request_id is a simple string; some test helpers pass a Hash as headers
    request_id = request_id["id"] || request_id[:id] || "no_request_id" if request_id.is_a?(Hash)
    request_id = request_id.to_s
    Thread.current[:request_id] = request_id if request_id.present?
    @app.call(env)
  ensure
    Thread.current[:request_id] = nil
  end
end

# Add middleware to capture request_id
Rails.application.config.middleware.insert_after ActionDispatch::RequestId, RequestIdMiddleware

# Set up exception logging using ActiveSupport::Notifications
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  payload = event.payload
  if payload[:exception_object]
    exception = payload[:exception_object]
    Rails.logger.error("Unhandled exception: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace
  end
end

# Handle Rails startup errors
if defined?(Rails::Server)
  Rails.application.config.after_initialize do
      # Run startup checks
      Rails.logger.debug "✓ Logger configured successfully."
  rescue StandardError => e
      Rails.logger.debug "\n[FATAL] Error during application initialization: #{e.message}"
      Rails.logger.debug e.backtrace.join("\n")
      # Don't use exit directly, use Rails.application.exit! or abort
      abort("Application initialization failed") # This is the Rails-preferred way to exit
  end
end
