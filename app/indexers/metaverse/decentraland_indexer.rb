# frozen_string_literal: true

module Metaverse
  # Indexer for Decentraland metaverse content
  # Queries the Decentraland subgraph for parcels and fetches scene data from IPFS
  class DecentralandIndexer < BaseIndexer
    def fetch_items
      log_info "Fetching scene data from Decentraland Catalyst Network"

      # Use the Catalyst Content Service API to fetch scenes
      cached_request(%w[catalyst scenes]) do
        scenes = []
        max_items = config.fetch("max_items", 10)

        # Get scenes by fetching a range of coordinates
        # Start from Genesis Plaza area and expand outward
        coordinates = generate_coordinate_list(max_items)

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

        raise "No scenes found in the requested coordinate range. The Catalyst server may be empty or the coordinate range may be outside populated areas." if scenes.empty?

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
      # Use actual coordinates that are known to have scenes in Decentraland
      coordinates = []

      # Genesis Plaza area (the main spawn area)
      coordinates << { x: -9, y: -9 }  # Part of Genesis Plaza
      coordinates << { x: 0, y: 0 }    # Genesis Plaza center
      coordinates << { x: -1, y: 0 }   # Adjacent to Genesis Plaza
      coordinates << { x: 1, y: 0 }    # Adjacent to Genesis Plaza
      coordinates << { x: 0, y: -1 }   # Adjacent to Genesis Plaza

      # Popular districts with known scenes
      coordinates << { x: -20, y: -20 } # Museum District
      coordinates << { x: 20, y: 20 }   # Fashion District
      coordinates << { x: -50, y: 50 }  # Casino District
      coordinates << { x: 75, y: -75 }  # Dragon City
      coordinates << { x: -100, y: 0 }  # Roads area

      # Return only the number requested
      coordinates.take(max_items)
    end

    def ipfs_gateway
      config.dig("api_endpoints", "ipfs_gateway") || "https://ipfs.io"
    end
  end
end
