# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails"

# Use SQLite as the database for Active Record with enhanced adapter
gem "activerecord-enhancedsqlite3-adapter"
gem "sqlite3"

# Use the Puma web server (multi-threaded, default for Rails)
# Pin to latest stable major; adjust as needed.
gem "puma"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use vite build system
gem "vite_plugin_legacy"
gem "vite_rails"

# Sentry-Ruby to track backend crashes
gem "sentry-rails"
gem "sentry-ruby"

# StimulusReflex framework
gem "ostruct"
gem "stimulus_reflex"

# Rodauth Rails integration for authentication
gem "argon2"
gem "rodauth-guest"
gem "rodauth-pwned"
gem "rodauth-rails"
gem "sequel-activerecord_connection"
gem "tilt"

# Solid cache and queue for caching and background jobs
gem "solid_cache"
gem "solid_queue"

# Solid Cable for database-backed ActionCable without Redis
gem "solid_cable"

# Used to monkey patch ActionCable to use the permessage_deflate extension
gem "permessage_deflate"

# Rack-Brotli to compress responses with Brotli
gem "rack-brotli"

# Zstandard to compress responses with Zstandard
gem "zstandard"

# Rate limit everything on the app
gem "rack-attack"

# CORS support
gem "rack-cors"

# Unicode to handle emoji
gem "unicode"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap"

# Secure XML parsing
gem "nokogiri"

# Active Storage validations
gem "active_storage_validations"

# Add lockbox gem for encrypted Active Storage attachments
gem "lockbox"

# Add view_component gem for ViewComponent support
gem "view_component"

# For model-level Rodauth integration
gem "rodauth-model"

# Use zip_kit for streaming zip exports
gem "zip_kit"

# Add the RE2 Ruby gem to enable the RE2-based whitespace compressor middleware
gem "re2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Make the code actually look good among other things
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rails"

  # Lint ERB files
  gem "erb_lint"

  # Use the erb formatter to format ERB files
  gem "erb-formatter"

  # fly.io's dockerfile generator to generate a docker compose file for the site.
  gem "dockerfile-rails"

  # Use fasterer for speed improvement hints
  gem "fasterer"

  # Use the brakeman gem to check for security vulnerabilities
  gem "brakeman"

  # foreman does not seem to be installed by rails automatically
  gem "foreman"

  # Use bundle-audit to check for security vulnerabilities
  gem "bundle-audit"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "mocha"
  gem "selenium-webdriver"
end
