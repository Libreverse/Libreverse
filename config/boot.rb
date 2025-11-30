# frozen_string_literal: true
# shareable_constant_value: literal

# Disable macOS fork safety check to prevent crashes during development
ENV["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] = "YES"

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Bootsnap Performance Optimization
require "bootsnap"

# Use ENV instead of Rails constants since Rails isn't loaded yet
Bootsnap.setup(
  cache_dir: File.expand_path("../tmp/cache", __dir__),
  ignore_directories: [ "node_modules" ],
  development_mode: ENV["RAILS_ENV"] == "development",
  load_path_cache: true,
  compile_cache_iseq: false,
  compile_cache_yaml: true,
  readonly: false
)

# Establish thread budgeting before Rails loads other initializers/config ERB
require_relative "thread_budget"
