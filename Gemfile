source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the falcon web server for better concurrency
gem "falcon", "~> 0.48.4"

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
gem "activerecord-session_store", "~> 2.0"

# Solid cache and queue for caching and background jobs
gem "solid_cache"
gem "solid_queue"

# Used to monkey patch ActionCable to use the permessage_deflate extension
gem "permessage_deflate"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# HTML compressor to minify HTML when sent to the client
gem "htmlcompressor", "~> 0.4.0"

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

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Use the actioncable-enhanced-postgresql-adapter gem for better scaling of stimulus reflex without redis
gem "actioncable-enhanced-postgresql-adapter"

# Use the authorio gem for the indieauth server implementation
gem "authorio-updated", git: "https://github.com/libreverse/authorio-updated.git"

# Use the omniauth-indieauth gem for the indieauth client implementation
gem "omniauth-indieauth-updated", git: "https://github.com/Libreverse/omniauth-indieauth-updated.git"

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
