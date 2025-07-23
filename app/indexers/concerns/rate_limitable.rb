# frozen_string_literal: true

# Concern for rate limiting API requests in indexers
module RateLimitable
  extend ActiveSupport::Concern

  included do
    attr_reader :rate_limiter
  end

  private

  def initialize_rate_limiter
    rate_limit = config.fetch("rate_limit", 10) # Default 10 requests per second
    @rate_limiter = RateLimiter.new(rate_limit)
  end

  def rate_limited?
    config.fetch("rate_limit", 0).positive?
  end

  def wait_for_rate_limit
    return unless rate_limited?

    @rate_limiter ||= initialize_rate_limiter
    @rate_limiter.wait_if_needed
  end

  def sleep_between_batches
    # Additional delay between batches to be extra respectful
    batch_delay = config.fetch("batch_delay", 1.0)
    sleep(batch_delay) if batch_delay.positive?
  end

  # Simple rate limiter implementation
  class RateLimiter
    def initialize(requests_per_second)
      @requests_per_second = requests_per_second.to_f
      @min_interval = 1.0 / @requests_per_second
      @last_request_time = nil
    end

    def wait_if_needed
      return if @requests_per_second <= 0

      now = Time.current.to_f

      if @last_request_time
        time_since_last = now - @last_request_time
        if time_since_last < @min_interval
          sleep_time = @min_interval - time_since_last
          sleep(sleep_time)
        end
      end

      @last_request_time = Time.current.to_f
    end
  end
end
