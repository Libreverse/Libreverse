# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Metaverse::DecentralandIndexer, type: :model do
  let(:indexer) { described_class.new }

  describe "Progressive Indexing" do
    before do
      # Clean up any existing test data
      IndexedContent.where(source_platform: 'decentraland').destroy_all
      Rails.cache.delete("decentraland_indexer_search_radius")
    end

    describe "#generate_spiral_coordinates" do
      it "generates coordinates in spiral pattern" do
        coordinates = indexer.send(:generate_spiral_coordinates, 0, 0, 2)
        
        # Should include center
        expect(coordinates).to include({ x: 0, y: 0 })
        
        # Should include adjacent coordinates
        expect(coordinates).to include({ x: 1, y: 0 })
        expect(coordinates).to include({ x: -1, y: 0 })
        expect(coordinates).to include({ x: 0, y: 1 })
        expect(coordinates).to include({ x: 0, y: -1 })
        
        # Should not have duplicates
        expect(coordinates.uniq.length).to eq(coordinates.length)
      end
      
      it "respects radius limit" do
        coordinates = indexer.send(:generate_spiral_coordinates, 0, 0, 1)
        
        # Should not include coordinates beyond radius 1
        expect(coordinates).not_to include({ x: 2, y: 0 })
        expect(coordinates).not_to include({ x: 0, y: 2 })
      end
    end

    describe "#get_indexed_coordinates_set" do
      it "returns empty set when no content indexed" do
        result = indexer.send(:get_indexed_coordinates_set)
        expect(result).to be_empty
      end
      
      it "returns coordinates of indexed content" do
        IndexedContent.create!(
          source_platform: 'decentraland',
          external_id: 'test-1',
          content_type: 'scene',
          title: 'Test Scene',
          coordinates: { x: 5, y: 10 },
          last_indexed_at: Time.current
        )
        
        result = indexer.send(:get_indexed_coordinates_set)
        expect(result).to include("5,10")
      end
    end

    describe "#daily_limit_reached?" do
      context "when no daily limit is set" do
        before do
          allow(indexer).to receive(:config).and_return({})
        end
        
        it "returns false" do
          expect(indexer.send(:daily_limit_reached?)).to be false
        end
      end
      
      context "when daily limit is set" do
        before do
          allow(indexer).to receive(:config).and_return({ "daily_limit" => 5 })
        end
        
        it "returns false when under limit" do
          # Create 3 items indexed today
          3.times do |i|
            IndexedContent.create!(
              source_platform: 'decentraland',
              external_id: "test-#{i}",
              content_type: 'scene',
              title: "Test Scene #{i}",
              last_indexed_at: Time.current
            )
          end
          
          expect(indexer.send(:daily_limit_reached?)).to be false
        end
        
        it "returns true when at or over limit" do
          # Create 5 items indexed today
          5.times do |i|
            IndexedContent.create!(
              source_platform: 'decentraland',
              external_id: "test-#{i}",
              content_type: 'scene',
              title: "Test Scene #{i}",
              last_indexed_at: Time.current
            )
          end
          
          expect(indexer.send(:daily_limit_reached?)).to be true
        end
        
        it "ignores items indexed yesterday" do
          # Create 5 items indexed yesterday
          5.times do |i|
            IndexedContent.create!(
              source_platform: 'decentraland',
              external_id: "test-#{i}",
              content_type: 'scene',
              title: "Test Scene #{i}",
              last_indexed_at: 1.day.ago
            )
          end
          
          expect(indexer.send(:daily_limit_reached?)).to be false
        end
      end
    end

    describe "#generate_progressive_coordinates" do
      before do
        allow(indexer).to receive(:config).and_return({ "daily_limit" => 10 })
      end
      
      it "returns empty array when daily limit reached" do
        allow(indexer).to receive(:daily_limit_reached?).and_return(true)
        
        result = indexer.send(:generate_coordinate_list, 5)
        expect(result).to be_empty
      end
      
      it "excludes already indexed coordinates" do
        # Index coordinate (0,0)
        IndexedContent.create!(
          source_platform: 'decentraland',
          external_id: 'test-origin',
          content_type: 'scene',
          title: 'Origin Scene',
          coordinates: { x: 0, y: 0 },
          last_indexed_at: Time.current
        )
        
        result = indexer.send(:generate_progressive_coordinates, 5)
        
        # Should not include (0,0) since it's already indexed
        expect(result).not_to include({ x: 0, y: 0 })
        # Should include other nearby coordinates
        expect(result.size).to be > 0
      end
    end

    describe "#get_current_search_radius" do
      it "starts with default radius of 5" do
        expect(indexer.send(:get_current_search_radius)).to eq(5)
      end
    end

    describe "#expand_search_radius" do
      it "increases search radius by 5" do
        initial_radius = indexer.send(:get_current_search_radius)
        indexer.send(:expand_search_radius)
        new_radius = indexer.send(:get_current_search_radius)
        
        expect(new_radius).to eq(initial_radius + 5)
      end
      
      it "caps search radius at 50" do
        # Set radius to 48
        Rails.cache.write("decentraland_indexer_search_radius", 48)
        
        indexer.send(:expand_search_radius)
        radius = indexer.send(:get_current_search_radius)
        
        expect(radius).to eq(50) # Should cap at 50, not go to 53
      end
    end
  end
end
