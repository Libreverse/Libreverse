# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Establish thread budgeting before Rails loads other initializers/config ERB
begin
	require_relative "thread_budget"
rescue LoadError => e
	warn "Thread budget not loaded: #{e.message}"
end
