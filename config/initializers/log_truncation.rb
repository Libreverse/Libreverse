# frozen_string_literal: true

require "active_support/ordered_options"
require "active_support/logger"
require "active_support/tagged_logging"

module LogFormatting
  DEFAULT_OMISSION = "…(truncated)".freeze

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
      return 2000
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

if defined?(ActiveSupport::Logger::SimpleFormatter)
  LogFormatting::FormatterPrepend.prepend_truncation!(ActiveSupport::Logger::SimpleFormatter)
end

if defined?(ActiveSupport::TaggedLogging::Formatter)
  LogFormatting::FormatterPrepend.prepend_truncation!(ActiveSupport::TaggedLogging::Formatter)
end
