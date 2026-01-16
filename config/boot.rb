# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Disable macOS fork safety check to prevent crashes during development
ENV["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] = "YES"

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

if RUBY_ENGINE == "truffleruby"
  require 'ractor/shim'
end

# Load Rails 8.1.1 compatibility patch
require_relative "patches/rails_811_attr_reader_fix"

# Bootsnap Performance Optimization
require "bootsnap"

# Use ENV instead of Rails constants since Rails isn't loaded yet
Bootsnap.setup(
  cache_dir: File.expand_path("../tmp/cache", __dir__),
  ignore_directories: [ "node_modules" ],
  development_mode: ENV["RAILS_ENV"] == "development",
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true,
  readonly: false
)

# Ruby-Next setup – place this block right after Bootsnap.setup
require "ruby-next/language/setup"

# Runtime transpilation only in development (Bootsnap-integrated for safety)
if ENV["RAILS_ENV"] == "development"
  require "ruby-next/language/runtime"
  # Optional: Customize include/exclude patterns if needed
  # RubyNext::Language.include_patterns = [File.expand_path("../app", __dir__), File.expand_path("../lib", __dir__)]
  # RubyNext::Language.exclude_patterns << /vendor/
end

# Establish thread budgeting before Rails loads other initializers/config ERB
require_relative "thread_budget"