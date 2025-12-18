# frozen_string_literal: true
# shareable_constant_value: literal

# TruffleRuby JIT Warmup Initializer
#
# Pre-warms the JIT compiler by exercising common code paths after boot.
# This reduces latency for the first real user requests.
#
# Configuration via environment variables:
#   JIT_WARMUP_ENABLED=1       - Force enable warmup (auto-enabled on TruffleRuby)
#   JIT_WARMUP_DISABLED=1      - Force disable warmup
#   JIT_WARMUP_ASYNC=1         - Run warmup in background thread (default in production)
#   JIT_WARMUP_DELAY=2.0       - Seconds to wait before async warmup
#   JIT_WARMUP_RUNS=3          - Number of iterations per route
#   JIT_WARMUP_HOST=localhost  - Host header for warmup requests
#

Rails.application.config.after_initialize do
  next if ENV['JIT_WARMUP_DISABLED'] == '1'
  next unless warmup_enabled?

  # Skip warmup in test environment
  next if Rails.env.test?

  # Skip warmup in console or rake tasks
  next if defined?(Rails::Console) || File.basename($PROGRAM_NAME) == 'rake'

  warmup_options = {
    runs: ENV.fetch('JIT_WARMUP_RUNS', nil)&.to_i,
    silent: !Rails.env.development?
  }.compact

  if async_warmup?
    delay = ENV.fetch('JIT_WARMUP_DELAY', '2.0').to_f
    Rails.logger.info("[JitWarmup] Scheduling async warmup in #{delay}s")
    JitWarmupService.warmup_async(delay: delay, **warmup_options)
  else
    Rails.logger.info('[JitWarmup] Running synchronous warmup')
    JitWarmupService.warmup(**warmup_options)
  end
end

# Helper to determine if warmup should run
def warmup_enabled?
  return true if ENV['JIT_WARMUP_ENABLED'] == '1'
  return true if ENV['FORCE_JIT_WARMUP'] == '1'

  # Auto-enable on TruffleRuby
  RUBY_ENGINE == 'truffleruby'
end

# Helper to determine warmup mode
def async_warmup?
  return true if ENV['JIT_WARMUP_ASYNC'] == '1'

  # Default to async in production to not block startup
  Rails.env.production?
end
