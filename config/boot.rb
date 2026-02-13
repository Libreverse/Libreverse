# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Boot tracing module (defined before shareable_constant_value to avoid restrictions)
module BootTrace
  def self.log(event)
    return unless ENV["TRACE_BOOT"] == "1"

    trace_file = File.expand_path("../tmp/boot_trace.log", __dir__)
    File.open(trace_file, "a") do |f|
      f.puts(event.to_s)
      f.flush
    end
  rescue StandardError
    nil
  end
end

# Disable macOS fork safety check to prevent crashes during development
ENV["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] = "YES"

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

BootTrace.log("boot.rb: start")

require "bundler/setup" # Set up gems listed in the Gemfile.
BootTrace.log("boot.rb: bundler/setup loaded")

if RUBY_ENGINE == "truffleruby"
  require "ractor/shim"
  BootTrace.log("boot.rb: ractor/shim loaded")
end

# Load Rails 8.1.1 compatibility patch
BootTrace.log("boot.rb: loading rails_811_attr_reader_fix")
require_relative "patches/rails_811_attr_reader_fix"
BootTrace.log("boot.rb: rails_811_attr_reader_fix loaded")

# Bootsnap Performance Optimization
BootTrace.log("boot.rb: loading bootsnap")
require "bootsnap"
BootTrace.log("boot.rb: bootsnap loaded")

# Use ENV instead of Rails constants since Rails isn't loaded yet
BootTrace.log("boot.rb: configuring bootsnap")
Bootsnap.setup(
  cache_dir: File.expand_path("../tmp/cache", __dir__),
  ignore_directories: [ "node_modules" ],
  development_mode: ENV["RAILS_ENV"] == "development",
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true,
  readonly: false
)
BootTrace.log("boot.rb: bootsnap configured")

# Ruby-Next setup – place this block right after Bootsnap.setup
BootTrace.log("boot.rb: loading ruby-next/language/setup")
require "ruby-next/language/setup"
BootTrace.log("boot.rb: ruby-next/language/setup loaded")

# Runtime transpilation only in development (Bootsnap-integrated for safety)
if ENV["RAILS_ENV"] == "development"
  BootTrace.log("boot.rb: loading ruby-next/language/runtime (development)")
  require "ruby-next/language/runtime"
  BootTrace.log("boot.rb: ruby-next/language/runtime loaded")
  # Optional: Customize include/exclude patterns if needed
  # RubyNext::Language.include_patterns = [File.expand_path("../app", __dir__), File.expand_path("../lib", __dir__)]
  # RubyNext::Language.exclude_patterns << /vendor/
end

BootTrace.log("boot.rb: complete")
