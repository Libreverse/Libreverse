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

# Log capture system for tests - only show logs for failing tests
module TestLogCapture
  @original_logger = nil
  @current_test_logs = nil
  @capture_enabled = false

  def self.setup
    return if @original_logger

    @original_logger = Rails.logger.dup
  end

  def self.enable_capture
    @capture_enabled = true
  end

  def self.disable_capture
    @capture_enabled = false
  end

  def self.start_capture_for_test
    return unless @original_logger && @capture_enabled

    # Create a string buffer to capture logs
    @current_test_logs = StringIO.new

    # Clone the original logger's configuration but redirect output to our buffer
    buffer_logger = @original_logger.dup
    buffer_logger.instance_variable_set(:@logdev, Logger::LogDevice.new(@current_test_logs))
    buffer_logger.level = Logger::DEBUG # Capture all logs during test

    # Replace Rails logger temporarily
    Rails.logger = buffer_logger
  end

  def self.finish_capture_for_test(test_instance, test_name)
    return unless @original_logger

    # Restore original logger
    Rails.logger = @original_logger if @capture_enabled

    # Check if test passed by examining the test instance
    test_passed = true
    if test_instance.respond_to?(:passed?) && !test_instance.passed?
      test_passed = false
    elsif test_instance.respond_to?(:failure) && test_instance.failure
      test_passed = false
    end

    # Only output captured logs if the test failed
    if !test_passed && @current_test_logs && @capture_enabled
      captured_logs = @current_test_logs.string
      if captured_logs.present?
        puts "\n#{'=' * 80}"
        puts "LOGS FOR FAILED TEST: #{test_name}"
        puts "=" * 80
        puts captured_logs
        puts "#{'=' * 80}\n"
      end
    end

    # Clean up
    @current_test_logs = nil
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Mocha does not play nicely with Minitest's parallel testing, leading to
    # `NoMethodError: undefined method 'pop' for nil` during teardown. Running
    # tests sequentially avoids this interference.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Set up log capture for each test - but disable during fixture loading
    setup do
      # TestLogCapture.setup
      # Enable capture only after fixtures are loaded
      # TestLogCapture.enable_capture
      # TestLogCapture.start_capture_for_test
    end

    # Finish log capture after each test
    teardown do
      # test_name = "#{self.class.name}##{method_name}"
      # TestLogCapture.finish_capture_for_test(self, test_name)
      # TestLogCapture.disable_capture
    end

    # Add more helper methods to be used by all tests here...

    # Helper method to disable fixtures for tests that don't need them
    def self.no_fixtures
      # This method prevents fixture loading for this test class
      self.use_transactional_tests = false
      self.fixture_sets = []
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
