# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Skip Vite Ruby compatibility check to avoid version mismatch errors
ENV["VITE_RUBY_SKIP_COMPATIBILITY_CHECK"] = "1"

# Load the Rails application.
require_relative "application"
BootTrace.log("environment.rb: application.rb loaded")

# Initialize the Rails application.
BootTrace.log("environment.rb: calling Rails.application.initialize!")
Rails.application.initialize!
BootTrace.log("environment.rb: Rails.application.initialize! complete")
BootTrace.log("environment.rb: complete")
