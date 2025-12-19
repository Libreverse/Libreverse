# frozen_string_literal: true

# TruffleRuby compatibility + TiDB transient retry
# ---------------------------------------------------------------------------

if Rails.env.development?
  # web-console 4.2.1 can raise when mapping ActiveRecord exceptions on TruffleRuby
  # (e.g., NoMethodError: undefined method `bindings` for ActiveRecord::StatementInvalid).
  # Disable it so the app can continue rendering even when the DB is temporarily unhealthy.
  if defined?(WebConsole::Middleware)
    Rails.application.config.middleware.delete(WebConsole::Middleware)
  end

  class TiDBTransientRetry
    MAX_RETRIES = 3

    def initialize(app)
      @app = app
    end

    def call(env)
      attempts = 0

      begin
        @app.call(env)
      rescue ActiveRecord::StatementInvalid => e
        raise unless retryable_tidb?(e.cause)

        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      rescue ActiveRecord::ConnectionNotEstablished => e
        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      rescue StandardError => e
        # Don't swallow unrelated application errors.
        raise unless retryable_connection_error?(e)

        attempts += 1
        raise if attempts > MAX_RETRIES

        ActiveRecord::Base.clear_active_connections! if defined?(ActiveRecord::Base)
        sleep(backoff(attempts))
        retry
      end
    end

    private

    def retryable_tidb?(cause)
      return false unless cause

      msg = cause.message.to_s
      msg.include?("Region is unavailable") ||
        msg.include?("trilogy_query_recv") ||
        msg.include?("trilogy_connect")
    end

    def retryable_connection_error?(error)
      klass = error.class.name
      return true if klass == "Trilogy::ConnectionError"

      msg = error.message.to_s
      msg.include?("trilogy_connect") || msg.include?("unable to connect")
    end

    def backoff(attempt)
      [ 0.1 * (2**(attempt - 1)), 1.0 ].min
    end
  end

  Rails.application.config.middleware.insert_before 0, TiDBTransientRetry
end
