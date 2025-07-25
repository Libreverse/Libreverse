#!/usr/bin/env ruby
# frozen_string_literal: true

require './config/environment'

puts '🚀 Testing metaverse content vectorization and search...'
puts ''

begin
  # Check if we have indexed content
  content_count = IndexedContent.count
  puts "📊 Found #{content_count} indexed content items"

  if content_count.positive?
    # Vectorize the indexed content
    puts "🔄 Vectorizing indexed content..."
    IndexedContent.find_each do |content|
      puts "  - Vectorizing: #{content.title}"
      VectorizeIndexedContentJob.perform_now(content.id)
    end

    # Test search
    puts ''
    puts "🔍 Testing unified search..."

    test_queries = %w[plaza genesis metaverse decentraland]

    test_queries.each do |query|
      puts ''
      puts "Query: '#{query}'"
      results = ExperienceSearchService.search(query, include_metaverse: true, limit: 10)

      puts "  Found #{results.length} results:"
      i = 0
      results.each do |item|
        case item
        when Experience
          puts "    #{i + 1}. [LOCAL] #{item.title} by #{item.author}"
        when IndexedContent
          puts "    #{i + 1}. [#{item.source_platform.upcase}] #{item.title} by #{item.author}"
        else
          puts "    #{i + 1}. [UNKNOWN] #{item.class}: #{item.try(:title) || item.inspect}"
        end
        i += 1
      end
    end
  else
    puts "❌ No indexed content found. Run the Decentraland indexer first."
  end
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  puts "   #{e.backtrace.first}"
end
