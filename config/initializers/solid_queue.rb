# frozen_string_literal: true

# Solid Queue runtime tuning and safety for TiDB
Rails.application.configure do
  # Disable SKIP LOCKED to avoid TiDB protocol errors with locking reads.
  # This mirrors the environment config and ensures the setting is applied early.
  config.after_initialize do
    begin
      SolidQueue.use_skip_locked = false if defined?(SolidQueue)
    rescue => e
      Rails.logger.warn("SolidQueue.use_skip_locked setup failed: #{e.class}: #{e.message}")
    end
  end
end
# frozen_string_literal: true

# Use the main Rails logger (STDOUT with our custom formatter)
Rails.application.config.solid_queue.logger = Rails.logger
