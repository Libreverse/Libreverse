# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

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

    # Silence noisy Sidekiq heartbeat messages in development
    return nil if severity == "DEBUG" && message_string.include?("Sidekiq")

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

# frozen_string_literal: true
# shareable_constant_value: literal

# Filter Sensitive Parameters from Logs
# See ActiveSupport::ParameterFilter documentation for supported patterns.
# Credentials and authentication: secret, token, _key, crypt, salt, certificate, otp, ssn
# Personal identifying information: name, username, email, address, phone, birth, gender, national
# Financial information: card, account, iban, bank, tax, income
# Health information: health, medical, insurance
# Session and security related: csrf, xsrf, session, cookie, auth
# Other sensitive fields: social, verification, answer, key, secret_question
Rails.application.config.filter_parameters += %i[
  passw
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  name
  username
  email
  address
  phone
  birth
  gender
  national
  card
  account
  iban
  bank
  tax
  income
  health
  medical
  insurance
  csrf
  xsrf
  session
  cookie
  auth
  social
  verification
  answer
  key
  secret_question
]

# frozen_string_literal: true
# shareable_constant_value: literal

require "active_support/ordered_options"
require "active_support/tagged_logging"

module LogFormatting
  DEFAULT_OMISSION = "…(truncated)"

  class << self
    attr_reader :max_message_length, :omission

    def configure(max_length: nil, omission: nil)
      @max_message_length = sanitize_length(max_length)
      @omission = (omission || DEFAULT_OMISSION).dup.freeze
      update_rails_configuration!
    end

    def truncation_enabled?
      max_message_length.positive?
    end

    def truncate(message)
      string = message.to_s
      return string unless truncation_enabled?
      return string if string.length <= max_message_length

      slice_length = max_message_length - omission.length
      slice_length = 0 if slice_length.negative?

      head = slice_length.positive? ? string[0, slice_length] : ""
      "#{head}#{omission}"
    end

    private

    def sanitize_length(length)
      value = length.nil? ? default_length : length
      value = value.to_i
      value.positive? ? value : 0
    end

    def default_length
      2000
    end

    def update_rails_configuration!
      return unless defined?(Rails) && Rails.respond_to?(:configuration)

      config = Rails.configuration
      return unless config.respond_to?(:x)

      config.x.logging ||= ActiveSupport::OrderedOptions.new
      config.x.logging.max_message_length = @max_message_length
      config.x.logging.omission = @omission
    end
  end

  configure(
    max_length: ENV["RAILS_LOG_MAX_MESSAGE_LENGTH"],
    omission: ENV["RAILS_LOG_TRUNCATION_OMISSION"]
  )
end

module LogFormatting
  module TruncatingFormatter
    def call(severity, time, progname, msg)
      truncated = LogFormatting.truncate(msg2str(msg))
      super(severity, time, progname, truncated)
    end
  end

  module FormatterPrepend
    def prepend_truncation!(target)
      return unless target

      target.prepend(TruncatingFormatter)
    end
    module_function :prepend_truncation!
  end
end

LogFormatting::FormatterPrepend.prepend_truncation!(Logger::Formatter)

LogFormatting::FormatterPrepend.prepend_truncation!(ActiveSupport::Logger::SimpleFormatter) if defined?(ActiveSupport::Logger::SimpleFormatter)

LogFormatting::FormatterPrepend.prepend_truncation!(ActiveSupport::TaggedLogging::Formatter) if defined?(ActiveSupport::TaggedLogging::Formatter)
