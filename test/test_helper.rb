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
      def self.fixtures(*); end
    end
  end
end

# Override ApplicationController methods for tests
module ActionController
  class TestCase
    # We'll stub necessary methods in individual test classes
  end
end
