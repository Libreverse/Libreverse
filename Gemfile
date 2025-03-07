source "https://rubygems.org"

ruby "3.4.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"

# Use postgresql as the database for Active Record
gem "pg"

# Use the falcon web server for better concurrency
gem "falcon"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use vite build system
gem "vite_rails"

# Sentry-Ruby to track backend crashes
gem "sentry-rails"
gem "sentry-ruby"

# StimulusReflex framework
gem "activerecord-session_store"
gem "stimulus_reflex"
gem "ostruct"

# Solid cache and queue for caching and background jobs
gem "solid_cache"
gem "solid_queue"

# Used to monkey patch ActionCable to use the permessage_deflate extension
gem "permessage_deflate"

# HTML compressor to minify HTML when sent to the client
gem "htmlcompressor"

# Rack-Brotli to compress responses with Brotli
gem "rack-brotli"

# Rate limit everything on the app
gem "rack-attack"

# Unicode to handle emoji
gem "unicode"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: true

# Use the actioncable-enhanced-postgresql-adapter gem for better scaling of stimulus reflex without redis
gem "actioncable-enhanced-postgresql-adapter"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Make the code actually look good
  gem "rubocop"
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
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem "rodauth-rails", "~> 2.0"
# Enables Sequel to use Active Record's database connection
gem "sequel-activerecord_connection", "~> 2.0"
# Used by Rodauth for password hashing
gem "argon2", "~> 2.3"
# Used by Rodauth for rendering built-in view and email templates
gem "tilt", "~> 2.4"
