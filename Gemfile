source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"

# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"

# Use the falcon web server for better concurrency
gem "falcon", "~> 0.48.3"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use vite build system
gem "vite_rails"

# Sentry-Ruby to track backend crashes
gem "sentry-ruby"
gem "sentry-rails"

# StimulusReflex framework
gem "stimulus_reflex", "~> 3.5"
gem "action-cable-redis-backport", "~> 1"
gem "redis-session-store", "~> 0.11.5"

# Rack-Brotli to compress responses with Brotli
gem "rack-brotli"

# Use Redis adapter to run Action Cable in production and for caching
gem "redis", ">= 4.0.1"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# HTML compressor to minify HTML when sent to the client
gem "htmlcompressor", "~> 0.4.0"

# Rack-attack to rate-limit HTTP endpoints
gem "rack-attack"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: true

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Make the code actually look good
  gem "rubocop-rails-omakase"

  # Lint ERB files
  gem "erb_lint"

  # Use the erb formatter to format ERB files
  gem "erb-formatter", "~> 0.7.3"

  # fly.io's dockerfile generator to generate a docker compose file for the site.
  gem "dockerfile-rails", ">= 1.6"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
