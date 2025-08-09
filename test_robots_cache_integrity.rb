#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone test script for robots cache integrity checking
# Run with: ruby test_robots_cache_integrity.rb

require "bundler/setup"
require "rails"
require "active_support"
require "argon2"
require "robots"

# Mock the Rails environment for testing
class MockRails
  def self.application
    @application ||= MockApplication.new
  end

  def self.cache
    @cache ||= MockCache.new
  end
end

class MockApplication
  attr_accessor :secret_key_base

  def initialize
    @secret_key_base = "test_secret_key_base_for_robots_cache_integrity_testing_this_is_long_enough"
  end
end

class MockCache
  def initialize
    @store = {}
  end

  def read(key)
    @store[key]
  end

  def write(key, value, _options = {})
    @store[key] = value
  end

  delegate :clear, to: :@store
end

# Mock the indexer class with just the integrity methods
class TestRobotsCacheIntegrity
  # Copy the exact methods from BaseIndexer
  def generate_cache_integrity_hash(data, domain)
    salt = "robots_cache_#{domain}"

    key_generator = ActiveSupport::KeyGenerator.new(
      MockRails.application.secret_key_base,
      iterations: 1000
    )
    pepper = key_generator.generate_key("robots_cache_integrity", 32)

    input = "#{data}#{pepper}"

    argon2 = Argon2::Password.new(
      t_cost: 1,
      m_cost: 12,
      p_cost: 1,
      secret: pepper
    )

    argon2.create(input, salt)
  end

  def verify_cache_integrity(data, domain, stored_hash)
    key_generator = ActiveSupport::KeyGenerator.new(
      MockRails.application.secret_key_base,
      iterations: 1000
    )
    pepper = key_generator.generate_key("robots_cache_integrity", 32)

    argon2 = Argon2::Password.new
    begin
      argon2.verify_password(stored_hash, "#{data}#{pepper}", "robots_cache_#{domain}")
    rescue Argon2::ArgonHashFail
      false
    end
  end
end

# Test suite
class RobotsCacheIntegrityTest
  def initialize
    @tester = TestRobotsCacheIntegrity.new
    @test_count = 0
    @passed_count = 0
  end

  def run_all_tests
    puts "🔒 Testing Robots Cache Integrity Implementation"
    puts "=" * 50

    test_basic_integrity_generation
    test_integrity_verification_success
    test_integrity_verification_failure
    test_domain_specific_salting
    test_data_tampering_detection
    test_secret_key_dependency
    test_performance

    puts "\n#{'=' * 50}"
    puts "✅ Passed: #{@passed_count}/#{@test_count} tests"
    puts @passed_count == @test_count ? "🎉 All tests passed!" : "❌ Some tests failed!"
  end

  private

  def test(name)
    @test_count += 1
    print "Testing #{name}... "

    begin
      result = yield
      if result
        puts "✅ PASS"
        @passed_count += 1
      else
        puts "❌ FAIL"
      end
    rescue StandardError => e
      puts "💥 ERROR: #{e.message}"
    end
  end

  def test_basic_integrity_generation
    test "basic integrity hash generation" do
      data = "test_data_123"
      domain = "example.com"

      hash = @tester.generate_cache_integrity_hash(data, domain)

      # Should generate a valid Argon2 hash
      hash.is_a?(String) && hash.start_with?("$argon2") && hash.length > 50
    end
  end

  def test_integrity_verification_success
    test "integrity verification with valid data" do
      data = "robots_parser_data_test"
      domain = "test.example.com"

      # Generate hash
      hash = @tester.generate_cache_integrity_hash(data, domain)

      # Verify with same data - should pass
      @tester.verify_cache_integrity(data, domain, hash)
    end
  end

  def test_integrity_verification_failure
    test "integrity verification with tampered data" do
      data = "original_data"
      tampered_data = "tampered_data"
      domain = "test.example.com"

      # Generate hash with original data
      hash = @tester.generate_cache_integrity_hash(data, domain)

      # Verify with tampered data - should fail
      !@tester.verify_cache_integrity(tampered_data, domain, hash)
    end
  end

  def test_domain_specific_salting
    test "domain-specific salting prevents cross-domain attacks" do
      data = "same_robots_data"
      domain1 = "example.com"
      domain2 = "different.com"

      hash1 = @tester.generate_cache_integrity_hash(data, domain1)
      hash2 = @tester.generate_cache_integrity_hash(data, domain2)

      # Same data, different domains should produce different hashes
      hash1 != hash2 &&
        # Each should verify correctly with its own domain
        @tester.verify_cache_integrity(data, domain1, hash1) &&
        @tester.verify_cache_integrity(data, domain2, hash2) &&
        # But not with the wrong domain
        !@tester.verify_cache_integrity(data, domain1, hash2) &&
        !@tester.verify_cache_integrity(data, domain2, hash1)
    end
  end

  def test_data_tampering_detection
    test "detection of various tampering attempts" do
      data = "sensitive_robots_data"
      domain = "secure.example.com"

      hash = @tester.generate_cache_integrity_hash(data, domain)

      # Test various tampering scenarios
      tampering_attempts = [
        "#{data}x",           # append data
        "x#{data}",           # prepend data
        data.swapcase,        # case change
        data.reverse,         # reverse data
        "",                   # empty data
        "completely_different_data"
      ]

      # All tampering attempts should fail verification
      tampering_attempts.all? do |tampered|
        !@tester.verify_cache_integrity(tampered, domain, hash)
      end
    end
  end

  def test_secret_key_dependency
    test "hashes depend on secret key" do
      data = "test_data"
      domain = "example.com"

      # Generate hash with current secret
      hash1 = @tester.generate_cache_integrity_hash(data, domain)

      # Mock different secret key
      original_secret = MockRails.application.instance_variable_get(:@secret_key_base)
      MockRails.application.instance_variable_set(:@secret_key_base, "different_secret_key")

      hash2 = @tester.generate_cache_integrity_hash(data, domain)

      # Restore original secret
      MockRails.application.instance_variable_set(:@secret_key_base, original_secret)

      # Different secrets should produce different hashes
      hash1 != hash2
    end
  end

  def test_performance
    test "performance is reasonable" do
      data = "performance_test_data" * 100 # Larger data
      domain = "performance.example.com"

      # Measure generation time
      start_time = Time.zone.now
      hash = @tester.generate_cache_integrity_hash(data, domain)
      generation_time = Time.zone.now - start_time

      # Measure verification time
      start_time = Time.zone.now
      verified = @tester.verify_cache_integrity(data, domain, hash)
      verification_time = Time.zone.now - start_time

      puts "\n    Generation time: #{(generation_time * 1000).round(2)}ms"
      puts "    Verification time: #{(verification_time * 1000).round(2)}ms"

      # Should complete in reasonable time (less than 1 second each) and verify correctly
      generation_time < 1.0 && verification_time < 1.0 && verified
    end
  end
end

# Run the tests
RobotsCacheIntegrityTest.new.run_all_tests if __FILE__ == $PROGRAM_NAME
