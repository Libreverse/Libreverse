# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# Load the Rails application.
require_relative "application"
BootTrace.log("environment.rb: application.rb loaded")

# Initialize the Rails application.
BootTrace.log("environment.rb: calling Rails.application.initialize!")
Rails.application.initialize!
BootTrace.log("environment.rb: Rails.application.initialize! complete")
BootTrace.log("environment.rb: complete")
