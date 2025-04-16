# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

# Ensure proper setup for Mocha
Mocha.configure do |c|
  c.stubbing_non_existent_method = :prevent
  c.stubbing_method_unnecessarily = :prevent
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper method to disable fixtures for tests that don't need them
    def self.no_fixtures
      # This method prevents fixture loading for this test class
      class_eval { define_singleton_method(:fixtures) { |*| } }
    end
  end
end

# Override ApplicationController methods for tests
module ActionController
  class TestCase
    # Define helper method to set up authentication state
    setup do
      # Don't stub rodauth in tests - it's handled in the PasswordSecurityEnforcer concern
    end
  end
end

# Modify PasswordSecurityEnforcer module to always skip in tests
module PasswordSecurityEnforcer
  def enforce_password_security
    return if Rails.env.test?

    super
  end
end
