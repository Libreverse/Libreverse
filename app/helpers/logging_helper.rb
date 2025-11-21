# frozen_string_literal: true
# shareable_constant_value: literal

# A helper module for standardized logging throughout the application
# Usage: include LoggingHelper in your class, then use the log_* methods
module LoggingHelper
  # Log at DEBUG level with component identification
  def log_debug(component, message)
    Rails.logger.debug("[#{component}] #{message}")
  end

  # Log at INFO level with component identification
  def log_info(component, message)
    Rails.logger.info("[#{component}] #{message}")
  end

  # Log at WARN level with component identification
  def log_warn(component, message)
    Rails.logger.warn("[#{component}] #{message}")
  end

  # Log at ERROR level with component identification
  def log_error(component, message, exception = nil)
    Rails.logger.error("[#{component}] #{message}")
    return unless exception

      Rails.logger.error("[#{component}] Exception: #{exception.class} - #{exception.message}")
      Rails.logger.error("[#{component}] Backtrace: #{exception.backtrace.join("\n")}") if exception.backtrace
  end

  # Log a security event at WARN level
  def log_security_event(component, event_type, details = {})
    message = "Security event - #{event_type}: #{details.inspect}"
    Rails.logger.warn("[#{component}] #{message}")
  end

  # Log performance metrics
  def log_performance(component, operation, duration_ms)
    Rails.logger.info("[#{component}] Performance - #{operation}: #{duration_ms}ms")
  end

  # Log database operations at DEBUG level
  def log_db_operation(component, operation, details = {})
    Rails.logger.debug("[#{component}] DB Operation - #{operation}: #{details.inspect}")
  end

  # Log user activities at INFO level
  def log_user_activity(component, account_id, action, details = {})
    Rails.logger.info("[#{component}] User #{account_id} - #{action}: #{details.inspect}")
  end

  # Simple timing method for performance logging
  def with_timing(component, operation)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration_ms = ((end_time - start_time) * 1000).round(2)
    log_performance(component, operation, duration_ms)
    result
  end
end
