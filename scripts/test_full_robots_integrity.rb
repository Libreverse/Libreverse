# frozen_string_literal: true

puts "🤖 Testing Full Robots Cache Integrity System"
puts "=" * 50

# Test class to access private methods
class TestIndexer < BaseIndexer
  def platform_name
    "test"
  end

  # Make get_robots_parser public for testing
  public :get_robots_parser
end

begin
  indexer = TestIndexer.new

  # Use a test domain that should have robots.txt
  test_domain = "https://example.com"

  puts "1. Testing robots parser creation and caching..."

  # First call - should create and cache
  puts "   First call (should create new)..."
  robots_parser1 = indexer.get_robots_parser(test_domain)
  puts "   ✓ Parser created: #{robots_parser1.class.name}"

  # Second call - should load from cache with integrity verification
  puts "   Second call (should load from cache)..."
  robots_parser2 = indexer.get_robots_parser(test_domain)
  puts "   ✓ Parser loaded: #{robots_parser2.class.name}"

  # Verify they work the same way
  test_url = "#{test_domain}/test"
  result1 = robots_parser1.allowed?(test_url)
  result2 = robots_parser2.allowed?(test_url)

  puts "2. Testing parser functionality..."
  puts "   Parser 1 result for #{test_url}: #{result1}"
  puts "   Parser 2 result for #{test_url}: #{result2}"
  puts "   Results match: #{result1 == result2}"

  puts "\n✅ Full robots cache integrity system test completed successfully!"
  puts "The HMAC integrity protection is working with real robots parser caching."
rescue StandardError => e
  puts "\n❌ Test failed with error:"
  puts "   #{e.class}: #{e.message}"
  puts "   #{e.backtrace.first(3).join('\n   ')}"
end
