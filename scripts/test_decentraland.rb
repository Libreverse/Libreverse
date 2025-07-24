#!/usr/bin/env ruby
# frozen_string_literal: true

require './config/environment'
puts '🚀 Testing improved Decentraland indexer...'
puts ''

begin
  # Clear existing data first
  IndexedContent.where(source_platform: 'decentraland').delete_all

  indexer = Metaverse::DecentralandIndexer.new
  indexer.index!
  puts ''

  # Check what was indexed
  count = IndexedContent.where(source_platform: 'decentraland').count
  puts "✅ SUCCESS: Indexed #{count} Decentraland scenes"

  # Show samples of what was indexed
  if count.positive?
    IndexedContent.where(source_platform: 'decentraland').limit(3).each_with_index do |content, i|
      puts ''
      puts "📋 Scene #{i + 1}:"
      puts "   Title: #{content.title}"
      puts "   Type: #{content.content_type}"
      puts "   Platform: #{content.source_platform}"
      puts "   Coordinates: (#{content.metadata['coordinates']['x']}, #{content.metadata['coordinates']['y']})"
      puts "   Scene ID: #{content.external_id[0..20]}..."
      puts "   Pointers: #{content.metadata['pointers']&.size || 0} parcels"
    end
  end
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  puts "   #{e.backtrace.first}"
end
