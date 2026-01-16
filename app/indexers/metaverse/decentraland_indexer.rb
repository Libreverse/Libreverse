# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

module Metaverse
  # Indexer for Decentraland metaverse content
  # Queries the Decentraland subgraph for parcels and fetches scene data from IPFS
  class DecentralandIndexer < BaseIndexer
    def fetch_items
      log_info "Fetching scene data from Decentraland Catalyst Network"

      # Use the Catalyst Content Service API to fetch scenes
      cached_request(%w[catalyst scenes]) do
        scenes = []
        max_items = config.fetch("max_items") { 10 }

        # Get scenes by fetching a range of coordinates
        # Progressive indexing: start from Genesis Plaza area and expand outward
        coordinates = generate_coordinate_list(max_items)

        if coordinates.empty?
          log_info "No new coordinates to index (daily limit reached or all coordinates processed)"
          return []
        end

        coordinates.each_slice(5) do |coord_batch|
          # Fetch multiple coordinates in one request using pointer array
          pointers = coord_batch.map { |coord| "#{coord[:x]},#{coord[:y]}" }
          response = make_request(catalyst_scenes_url(pointers))

          unless response.parsed_response.is_a?(Array)
            log_warn "Invalid response format from Catalyst: expected array, got #{response.parsed_response.class}"
            next
          end

          scenes.concat(response.parsed_response)

          # Rate limiting - be respectful to Catalyst servers
          sleep(0.1) unless coord_batch == coordinates.last(5)
        end

        log_info "Retrieved #{scenes.size} scenes from Catalyst Content Service"

        log_warn "No scenes found in the requested coordinate range. This may be normal for unexplored areas." if scenes.empty?

        scenes
      end
    rescue StandardError => e
      log_error "Failed to fetch from Decentraland Catalyst: #{e.message}"
      raise "Catalyst API Error: #{e.message}. Cannot fetch scene data from Catalyst network."
    end

    def process_item(scene)
      log_debug "Processing scene #{scene['id']}"

      # Extract coordinate from first pointer if available
      x = nil
      y = nil
      x, y = scene["pointers"].first.split(",").map(&:to_i) if scene["pointers"]&.first

      # Extract scene data from Catalyst API format
      processed_data = {
        id: scene["id"],
        type: scene["type"],
        timestamp: scene["timestamp"],
        pointers: scene["pointers"],
        metadata: scene["metadata"],
        content_files: scene["content"],
        x: x,
        y: y,
        raw_scene_data: scene
      }

      # Extract scene title and description from metadata
      if scene["metadata"]
        display = scene["metadata"]["display"] || {}
        processed_data[:scene_title] = display["title"]
        processed_data[:scene_description] = display["description"]
        processed_data[:scene_thumbnail] = display["navmapThumbnail"]
      end

      processed_data
    end

    protected

    def extract_external_id(raw_data)
      # Use the scene ID from Catalyst (it's the IPFS hash)
      raw_data[:id] || "#{raw_data[:x]},#{raw_data[:y]}"
    end

    def extract_content_type(raw_data)
      raw_data[:type] || "scene" # Catalyst returns 'scene' type
    end

    def extract_title(raw_data)
      # Try scene title first, then name, then coordinate-based title
      raw_data[:scene_title] ||
        raw_data[:name] ||
        "Scene (#{raw_data[:x]}, #{raw_data[:y]})"
    end

    def extract_description(raw_data)
      raw_data[:scene_description] ||
        raw_data[:description] ||
        "Decentraland scene at coordinates (#{raw_data[:x]}, #{raw_data[:y]})"
    end

    def extract_author(raw_data)
      # Extract from scene metadata if available
      raw_data.dig(:metadata, "contact", "name") ||
        raw_data.dig(:metadata, "owner") ||
        raw_data[:owner]
    end

    def extract_coordinates(raw_data)
      {
        x: raw_data[:x],
        y: raw_data[:y],
        platform: "decentraland"
      }
    end

    def extract_metadata(raw_data)
      metadata = {
        scene_id: raw_data[:id],
        scene_type: raw_data[:type],
        coordinates: { x: raw_data[:x], y: raw_data[:y] },
        timestamp: raw_data[:timestamp],
        pointers: raw_data[:pointers],
        content_files_count: raw_data[:content_files]&.size || 0
      }

      # Add scene display metadata if available
      if raw_data[:metadata]
        scene_meta = raw_data[:metadata]
        metadata[:scene_metadata] = {
          display: scene_meta["display"],
          scene: scene_meta["scene"],
          spawn_points: scene_meta["spawnPoints"],
          permissions: scene_meta["requiredPermissions"],
          allowed_media: scene_meta["allowedMediaHostnames"]
        }.compact
      end

      # Add content files info
      if raw_data[:content_files]
        metadata[:content_files] = raw_data[:content_files].map do |file|
          { file: file["file"], hash: file["hash"] }
        end
      end

      metadata
    end

    private

    def catalyst_content_server
      config.dig("api_endpoints", "catalyst_content") || "https://peer.decentraland.org/content"
    end

    def catalyst_scenes_url(pointers)
      pointer_params = pointers.map { |p| "pointer=#{p}" }.join("&")
      "#{catalyst_content_server}/entities/scenes?#{pointer_params}"
    end

    def generate_coordinate_list(max_items)
      # Progressive indexing: expand coverage over time
      # Check for daily limits first
      if daily_limit_reached?
        log_info "Daily indexing limit reached. Skipping until tomorrow."
        return []
      end

      # Get coordinates we haven't indexed yet
      unindexed_coordinates = generate_progressive_coordinates(max_items)

      if unindexed_coordinates.empty?
        # If we've exhausted the current search area, expand it
        log_info "Current search area exhausted. Expanding search radius."
        expand_search_radius
        unindexed_coordinates = generate_progressive_coordinates(max_items)
      end

      log_info "Generated #{unindexed_coordinates.size} unindexed coordinates (max: #{max_items})"
      unindexed_coordinates
    end

    def generate_progressive_coordinates(max_items)
      coordinates = []
      search_radius = get_current_search_radius

      # Start from center (Genesis Plaza) and spiral outward
      spiral_coordinates = generate_spiral_coordinates(0, 0, search_radius)

      # Filter out coordinates we've already indexed
      indexed_coordinates = get_indexed_coordinates_set

      spiral_coordinates.each do |coord|
        coord_key = "#{coord[:x]},#{coord[:y]}"
        next if indexed_coordinates.include?(coord_key)

        coordinates << coord
        break if coordinates.size >= max_items
      end

      # If we don't have enough from spiral, add some high-value known areas
      if coordinates.size < max_items
        high_value_coords = get_high_value_coordinates
        high_value_coords.each do |coord|
          coord_key = "#{coord[:x]},#{coord[:y]}"
          next if indexed_coordinates.include?(coord_key)

          coordinates << coord
          break if coordinates.size >= max_items
        end
      end

      coordinates
    end

    def generate_spiral_coordinates(center_x, center_y, max_radius)
      coordinates = []

      # Start with center point
      coordinates << { x: center_x, y: center_y }

      # Generate spiral pattern outward
      (1..max_radius).each do |radius|
        # Right side
        (-radius..radius).each do |dy|
          coordinates << { x: center_x + radius, y: center_y + dy }

        # Left side
        coordinates << { x: center_x - radius, y: center_y + dy }
        end

        # Top side (excluding corners already covered)
        ((-radius + 1)..(radius - 1)).each do |dx|
          coordinates << { x: center_x + dx, y: center_y + radius }

        # Bottom side (excluding corners already covered)
        coordinates << { x: center_x + dx, y: center_y - radius }
        end
      end

      coordinates.uniq
    end

    def get_high_value_coordinates
      [
        # Genesis Plaza area (the main spawn area)
        { x: -9, y: -9 },  # Part of Genesis Plaza
        { x: 0, y: 0 },    # Genesis Plaza center
        { x: -1, y: 0 },   # Adjacent to Genesis Plaza
        { x: 1, y: 0 },    # Adjacent to Genesis Plaza
        { x: 0, y: -1 },   # Adjacent to Genesis Plaza

        # Popular districts with known scenes
        { x: -20, y: -20 }, # Museum District
        { x: 20, y: 20 },   # Fashion District
        { x: -50, y: 50 },  # Casino District
        { x: 75, y: -75 },  # Dragon City
        { x: -100, y: 0 },  # Roads area

        # Additional high-traffic areas
        { x: -16, y: -16 }, # Near Genesis Plaza
        { x: 16, y: 16 },   # Fashion District area
        { x: -8, y: 8 },    # Cultural area
        { x: 8, y: -8 } # Entertainment area
      ]
    end

    def get_indexed_coordinates_set
      # Get all coordinates we've already indexed for Decentraland
      indexed_coords = IndexedContent
                       .where(source_platform: "decentraland")
                       .where.not(coordinates: nil)
                       .pluck(:coordinates)
                       .compact
                       .map { |coord_data| "#{coord_data['x']},#{coord_data['y']}" if coord_data.is_a?(Hash) && coord_data["x"] && coord_data["y"] }
                       .compact
                       .to_set

      log_debug "Found #{indexed_coords.size} already indexed coordinates"
      indexed_coords
    end

    def get_current_search_radius
      # Start with small radius and expand over time
      Rails.cache.fetch("decentraland_indexer_search_radius", expires_in: 7.days) do
        5 # Start with radius of 5 (11x11 grid around Genesis Plaza)
      end
    end

    def expand_search_radius
      current_radius = get_current_search_radius
      new_radius = [ current_radius + 5, 50 ].min # Expand by 5, max radius of 50
      Rails.cache.write("decentraland_indexer_search_radius", new_radius, expires_in: 7.days)
      log_info "Expanded search radius from #{current_radius} to #{new_radius}"
    end

    def daily_limit_reached?
      return false unless config["daily_limit"]

      daily_limit = config["daily_limit"].to_i
      return false if daily_limit <= 0

      # Count items indexed today
      today_start = Time.current.beginning_of_day
      today_count = IndexedContent
                    .where(source_platform: "decentraland")
                    .where("last_indexed_at >= ?", today_start)
                    .count

      if today_count >= daily_limit
        log_info "Daily limit reached: #{today_count}/#{daily_limit} items indexed today"
        return true
      end

      log_info "Daily progress: #{today_count}/#{daily_limit} items indexed today"
      false
    end

    def ipfs_gateway
      config.dig("api_endpoints", "ipfs_gateway") || "https://ipfs.io"
    end
  end
end
