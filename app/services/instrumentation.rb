class Instrumentation
  class << self
    # Record an error occurrence for monitoring/alerting
    def record_error(name, details = {})
      Rails.logger.error("#{name}: #{details.inspect}")
      
      # In a real app, you might send this to an error monitoring service
      # like Sentry, Bugsnag, Honeybadger, etc.
      # Example:
      # Sentry.capture_message("#{name} error", extra: details, level: 'error')
      
      increment_counter("errors.#{name}")
    end
    
    # Record a security event for monitoring/alerting
    def record_security_event(name, details = {})
      Rails.logger.warn("Security event - #{name}: #{details.inspect}")
      
      # Here you might send to a SIEM or security monitoring system
      increment_counter("security_events.#{name}")
    end
    
    # Increment a counter for metrics
    def increment_counter(key, amount = 1)
      # In a real app, this would send to your metrics system
      # e.g., StatsD, Prometheus, etc.
      # Example: 
      # $statsd.increment(key, by: amount)
      Rails.logger.debug("Metric: #{key} +#{amount}")
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