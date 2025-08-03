#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Decentraland indexer with wider search area
# Usage: rails runner scripts/test_decentraland_wide_search.rb

puts "=== Decentraland Wide Area Search Test ==="
puts "Current time: #{Time.current}"
puts

begin
  # Create indexer with expanded search configuration
  config_overrides = {
    "max_items" => 100,           # Limit to 100 items for testing
    "search_radius" => 5,         # Expand search radius to 5 (instead of default 2)
    "daily_coordinate_limit" => 200, # Allow more coordinates per day
    "batch_size" => 10,           # Smaller batches for testing
    "timeout" => 45               # Longer timeout for wider searches
  }

  puts "Creating Decentraland indexer with config:"
  config_overrides.each { |k, v| puts "  #{k}: #{v}" }
  puts

  indexer = Metaverse::DecentralandIndexer.new(config_overrides)

  puts "Platform: #{indexer.platform_name}"
  puts "Config loaded: #{!indexer.config.empty?}"
  puts

  puts "=== Fetching items with wider search area ==="

  # This will bypass cache due to wider search radius
  items = indexer.fetch_items

  puts "Found #{items.count} items to process"

  if items.count.positive?
    puts "\nFirst 5 items:"
    items.first(5).each_with_index do |item, i|
      puts "  #{i + 1}. Scene ID: #{item['id']}"
      puts "     Type: #{item['type']}"
      puts "     Pointers: #{item['pointers']&.first(3)&.join(', ')}"
      if item['metadata'] && item['metadata']['display']
        title = item['metadata']['display']['title']
        puts "     Title: #{title}" if title
      end
      puts
    end

    puts "=== Processing first few items ==="
    processed_count = 0

    items.first(5).each do |item|
        processed_item = indexer.process_item(item)
        puts "✅ Processed: #{processed_item[:scene_title] || processed_item[:id]}"
        puts "   Coordinates: (#{processed_item[:x]}, #{processed_item[:y]})"
        processed_count += 1
    rescue StandardError => e
        puts "❌ Failed to process #{item['id']}: #{e.message}"
    end

    puts "\nSuccessfully processed #{processed_count}/5 test items"

    # Test the make_request method specifically
    puts "\n=== Testing JSON API request method ==="
    begin
      test_url = indexer.send(:catalyst_scenes_url, [ "0,0", "1,1" ])
      puts "Test URL: #{test_url}"

      response = indexer.send(:make_request, test_url)
      puts "Response type: #{response.class.name}"
      puts "Response code: #{response.code}"
      puts "Parsed response type: #{response.parsed_response.class.name}"
      puts "Sample data available: #{response.parsed_response.is_a?(Array) && response.parsed_response.count.positive?}"
    rescue StandardError => e
      puts "❌ API request failed: #{e.message}"
    end

  else
    puts "No items found - this could indicate:"
    puts "  - All coordinates in the expanded area are already cached"
    puts "  - Daily coordinate limit reached"
    puts "  - API connectivity issues"
    puts "  - Configuration issues"
  end
rescue StandardError => e
  puts "❌ Test failed: #{e.class.name} - #{e.message}"
  puts "Backtrace:"
  puts(e.backtrace.first(5).map { |line| "  #{line}" })
end

puts "\n=== Test Complete ==="
