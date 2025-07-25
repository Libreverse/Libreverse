# frozen_string_literal: true

# Spring configuration for Libreverse application

# Watch additional configuration files that should trigger a restart
Spring.watch(
  ".ruby-version",
  ".rbenv-vars",
  "tmp/restart.txt",
  "tmp/caching-dev.txt",
  "config/bannedwords.yml",
  "config/spamwords.yml"
)

# Configure after_fork callbacks for any custom setup
Spring.after_fork do
  # Clear any caches that might have been established before forking
  Rails.application.config_for(:cache) if defined?(Rails) && Rails.application
end

# Set quiet mode to reduce noise during development
# Can be overridden by setting SPRING_QUIET environment variable
Spring.quiet = false
