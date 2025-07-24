#!/usr/bin/env ruby
# frozen_string_literal: true

require './config/environment'

puts '🚀 Running Decentraland indexer...'
indexer = Metaverse::DecentralandIndexer.new
indexer.index!

count = IndexedContent.where(source_platform: 'decentraland').count
puts "✅ Indexing completed - #{count} items indexed"
