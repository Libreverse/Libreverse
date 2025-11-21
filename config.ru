# frozen_string_literal: true
# shareable_constant_value: literal

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
