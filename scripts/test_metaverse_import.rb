#!/usr/bin/env ruby
# frozen_string_literal: true

require './config/environment'
puts '🚀 Testing Metaverse Experience Import System...'
puts ''

begin
  # Check what indexed content we have
  indexed_count = IndexedContent.where(source_platform: 'decentraland').count
  puts "📊 Found #{indexed_count} indexed Decentraland scenes"

  if indexed_count.zero?
    puts "❌ No indexed content found. Run the Decentraland indexer first."
    exit 1
  end

  # Show sample indexed content
  sample_content = IndexedContent.where(source_platform: 'decentraland').first
  puts ''
  puts "📋 Sample indexed content:"
  puts "   ID: #{sample_content.id}"
  puts "   Title: #{sample_content.title}"
  puts "   Platform: #{sample_content.source_platform}"
  puts "   External ID: #{sample_content.external_id[0..20]}..."

  # Check existing experiences before import
  existing_metaverse_experiences = Experience.indexed_metaverse.count
  puts ''
  puts "📈 Existing metaverse experiences: #{existing_metaverse_experiences}"

  # Import indexed content as experiences
  puts ''
  puts "🔄 Starting import process..."

  results = MetaverseExperienceImportService.bulk_import(
    IndexedContent.where(source_platform: 'decentraland')
  )

  puts ''
  puts "✅ Import completed!"
  puts "   Created: #{results[:created]} experiences"
  puts "   Updated: #{results[:updated]} experiences"
  puts "   Errors: #{results[:errors].size}"

  # Show errors if any
  results[:errors].each do |error|
    puts "   ❌ Error with indexed_content #{error[:indexed_content_id]}: #{error[:error]}"
  end

  # Show sample created experiences
  puts ''
  puts "📋 Sample created experiences:"
  Experience.indexed_metaverse.limit(3).each_with_index do |exp, i|
    puts ''
    puts "   Experience #{i + 1}:"
    puts "     Title: #{exp.title}"
    puts "     Source: #{exp.source_type} (#{exp.metaverse_platform})"
    puts "     Approved: #{exp.approved?}"
    puts "     Federates: #{exp.should_federate?}"
    puts "     Coordinates: #{exp.coordinates}"
    puts "     Author: #{exp.author}"
  end

  # Summary statistics
  puts ''
  puts "📊 Final Statistics:"
  puts "   Total Experiences: #{Experience.count}"
  puts "   User Created: #{Experience.user_created.count}"
  puts "   Indexed Metaverse: #{Experience.indexed_metaverse.count}"
  puts "   Federatable: #{Experience.federatable.count}"
  puts "   Decentraland: #{Experience.decentraland.count}"
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  puts "   #{e.backtrace.first}"
end
