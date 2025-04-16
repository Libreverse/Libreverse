# frozen_string_literal: true

class Instrumentation
  class << self
    # Record an error occurrence for monitoring/alerting
    def record_error(name, details = {})
      Rails.logger.error("#{name}: #{details.inspect}")

      # In a real app, you might send this to an error monitoring service
      # like Sentry, Bugsnag, Honeybadger, etc.
      # Example:
      # Sentry.capture_message("#{name} error", extra: details, level: 'error')

      record_metric_count("errors.#{name}")
    end

    # Record a security event for monitoring/alerting
    def record_security_event(name, details = {})
      Rails.logger.warn("Security event - #{name}: #{details.inspect}")

      # Here you might send to a SIEM or security monitoring system
      record_metric_count("security_events.#{name}")
    end

    # Increment a counter for metrics
    def log_metric_increment(key, amount = 1)
      # In a real app, this would send to your metrics system
      # e.g., StatsD, Prometheus, etc.
      # Example:
      # $statsd.increment(key, by: amount)
      Rails.logger.debug("Metric: #{key} +#{amount}")
    end

    # Record a metric count in a way that doesn't skip validations
    def record_metric_count(key, amount = 1)
      # Use the existing method for logging
      log_metric_increment(key, amount)

      # If you need to persist this in the database, use a method that doesn't skip validations
      # For example, find the record first and then update it:
      # metric = Metric.find_or_create_by(key: key)
      # metric.count += amount
      # metric.save
    end

    # Record a timing event
    def time(key)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield if block_given?
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Record the timing
      duration_ms = ((end_time - start_time) * 1000).to_i
      # $statsd.timing(key, duration_ms) # In a real app
      Rails.logger.debug("Timing: #{key} #{duration_ms}ms")

      result
    end
  end
end
