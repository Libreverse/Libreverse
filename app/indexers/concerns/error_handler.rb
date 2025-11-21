# frozen_string_literal: true
# shareable_constant_value: literal

# Concern for standardized error handling in indexers
module ErrorHandler
  extend ActiveSupport::Concern

  private

  def with_retry(max_retries: nil, delay: nil)
    max_retries ||= global_config.fetch("max_retries") { 3 }
    delay ||= global_config.fetch("retry_delay") { 5 }

    attempt = 0

    begin
      attempt += 1
      yield
    rescue StandardError => e
      if attempt <= max_retries && retryable_error?(e)
        log_warn "Attempt #{attempt}/#{max_retries} failed: #{e.message}. Retrying in #{delay}s..."
        sleep(delay)
        retry
      else
        log_error "All #{max_retries} attempts failed or non-retryable error: #{e.message}"
        raise
      end
    end
  end

  def retryable_error?(error)
    # Network errors, timeouts, and temporary server errors are retryable
    case error
    when Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      true
    when SocketError
      true
    when StandardError
      # HTTP errors that might be temporary
      if error.respond_to?(:response) && error.response
        status = error.response.code.to_i
        # Retry on server errors (5xx) and rate limiting (429)
        status >= 500 || status == 429
      else
        false
      end
    else
      false
    end
  end

  def handle_api_error(error, context = {})
    # Handle the case where error is already a Hash (legacy support)
    return error if error.is_a?(Hash)

    case error
    when Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      log_error "Request timeout: #{error.message}", context
    when SocketError
      log_error "Network error: #{error.message}", context
    when JSON::ParserError
      log_error "JSON parsing error: #{error.message}", context
    else
      log_error "Unexpected error: #{error.class.name} - #{error.message}", context
    end

    # Record error details for debugging
    {
      error_class: error.class.name,
      error_message: error.message,
      context: context,
      timestamp: Time.current.iso8601
    }
  end

  def timeout_for_request
    config.fetch("timeout") { global_config.fetch("default_timeout") { 30 } }
  end

  def global_config
    @global_config ||= begin
      Rails.application.config_for(:indexers)["global"] || {}
    rescue StandardError
      {}
    end
  end
end
