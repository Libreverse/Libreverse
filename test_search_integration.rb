#!/usr/bin/env ruby
# frozen_string_literal: true

require './config/environment'

puts '🧪 Testing metaverse search integration...'

# Create some test indexed content
indexed_content = IndexedContent.create!(
  external_id: 'test-parcel-123',
  source_platform: 'decentraland',
  title: 'Test Virtual Gallery',
  description: 'An amazing art gallery in Decentraland with interactive exhibits',
  author: 'TestUser',
  content_type: 'scene',
  coordinates: { x: 100, y: 50 },
  metadata: { 
    scene_type: 'gallery',
    interactive: true
  },
  last_indexed_at: Time.current
)

puts "✅ Created test IndexedContent: #{indexed_content.title}"

# Create a UnifiedExperience from the indexed content
unified = UnifiedExperience.new(indexed_content)
puts "✅ Created UnifiedExperience: #{unified.title}"
puts "   - Source type: #{unified.source_type}"
puts "   - Platform: #{unified.metaverse_platform}"
puts "   - Experience URL: #{unified.experience_url}"
puts "   - Is metaverse?: #{unified.metaverse?}"

# Test search integration
puts "\n🔍 Testing search with 'gallery'..."
results = ExperienceSearchService.search('gallery', limit: 10, use_vector_search: false)
puts "Found #{results.length} results:"
results.each do |result|
  if result.is_a?(IndexedContent)
    puts "   - [METAVERSE] #{result.title} (#{result.source_platform})"
  else
    puts "   - [LOCAL] #{result.title}"
  end
end

puts "\n🧹 Cleaning up test data..."
indexed_content.destroy
puts "✅ Test completed successfully!"
