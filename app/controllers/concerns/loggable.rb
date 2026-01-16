# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# A concern to easily include standardized logging capabilities in any class
# Usage: include Loggable in your class, then use log_* methods
module Loggable
  extend ActiveSupport::Concern
  include LoggingHelper

  included do
    # Set the component name automatically based on the class name
    def log_component
      @log_component ||= self.class.name.demodulize
    end

    # Override the component methods to use the automatically determined component name
    def log_debug(message)
      super(log_component, message)
    end

    def log_info(message)
      super(log_component, message)
    end

    def log_warn(message)
      super(log_component, message)
    end

    def log_error(message, exception = nil)
      super(log_component, message, exception)
    end

    def log_security_event(event_type, details = {})
      super(log_component, event_type, details)
    end

    def log_performance(operation, duration_ms)
      super(log_component, operation, duration_ms)
    end

    def log_db_operation(operation, details = {})
      super(log_component, operation, details)
    end

    def log_user_activity(account_id, action, details = {})
      super(log_component, account_id, action, details)
    end

    def with_timing(operation, &block)
      super(log_component, operation, &block)
    end
  end

  class_methods do
    # Class-level logging methods
    def log_component
      name.demodulize
    end

    def log_debug(message)
      Rails.logger.debug("[#{log_component}] #{message}")
    end

    def log_info(message)
      Rails.logger.info("[#{log_component}] #{message}")
    end

    def log_warn(message)
      Rails.logger.warn("[#{log_component}] #{message}")
    end

    def log_error(message, exception = nil)
      Rails.logger.error("[#{log_component}] #{message}")
      return unless exception

        Rails.logger.error("[#{log_component}] Exception: #{exception.class} - #{exception.message}")
        Rails.logger.error("[#{log_component}] Backtrace: #{exception.backtrace.join("\n")}") if exception.backtrace
    end
  end
end
