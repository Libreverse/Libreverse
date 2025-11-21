# frozen_string_literal: true
# shareable_constant_value: literal

namespace :indexing do
  desc "Test progressive indexing for Decentraland"
  task test_progressive: :environment do
    indexer = Metaverse::DecentralandIndexer.new

    puts "=== Progressive Indexing Test ==="
    puts "Current search radius: #{indexer.send(:get_current_search_radius)}"

    # Show current daily progress
    today_count = IndexedContent.where(source_platform: "decentraland")
                                .where("last_indexed_at >= ?", Time.current.beginning_of_day)
                                .count
    daily_limit = indexer.config["daily_limit"] || 0
    puts "Daily progress: #{today_count}/#{daily_limit} items indexed today"

    # Show already indexed coordinates
    indexed_coords = indexer.send(:get_indexed_coordinates_set)
    puts "Already indexed coordinates: #{indexed_coords.size}"

    # Generate next batch of coordinates
    max_items = 10
    coordinates = indexer.send(:generate_coordinate_list, max_items)
    puts "Next coordinates to index (#{coordinates.size}):"
    coordinates.each_with_index do |coord, i|
      puts "  #{i + 1}. (#{coord[:x]}, #{coord[:y]})"
    end

    puts "\nTo run actual indexing: rails runner 'Metaverse::DecentralandIndexer.new.index!'"
  end

  desc "Reset progressive indexing state"
  task reset_progressive: :environment do
    Rails.cache.delete("decentraland_indexer_search_radius")
    puts "Progressive indexing state reset. Search radius will start from 5 on next run."
  end

  desc "Show progressive indexing stats"
  task progressive_stats: :environment do
    puts "=== Progressive Indexing Statistics ==="

    # Overall stats
    total_indexed = IndexedContent.where(source_platform: "decentraland").count
    puts "Total scenes indexed: #{total_indexed}"

    # Daily stats
    today_count = IndexedContent.where(source_platform: "decentraland")
                                .where("last_indexed_at >= ?", Time.current.beginning_of_day)
                                .count
    puts "Scenes indexed today: #{today_count}"

    # Weekly stats
    week_count = IndexedContent.where(source_platform: "decentraland")
                               .where("last_indexed_at >= ?", 7.days.ago)
                               .count
    puts "Scenes indexed this week: #{week_count}"

    # Search radius
    search_radius = Rails.cache.read("decentraland_indexer_search_radius") || 5
    puts "Current search radius: #{search_radius}"

    # Coverage area (approximate)
    coverage_area = (2 * search_radius + 1)**2
    puts "Theoretical coverage area: #{coverage_area} parcels (#{search_radius}×#{search_radius} radius)"

    # Coordinate distribution
    if total_indexed.positive?
      coords = IndexedContent.where(source_platform: "decentraland")
                             .where.not(coordinates: nil)
                             .pluck(:coordinates)
                             .compact
                             .map { |c| c.is_a?(Hash) ? [ c["x"], c["y"] ] : nil }
                             .compact

      if coords.any?
        x_coords = coords.map(&:first)
        y_coords = coords.map(&:last)
        puts "Coordinate ranges: X(#{x_coords.min} to #{x_coords.max}), Y(#{y_coords.min} to #{y_coords.max})"
      end
    end
  end
end
