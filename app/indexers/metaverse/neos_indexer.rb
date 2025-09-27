module Metaverse
  # Indexer for NeosVR metaverse content
  # Fetches public sessions (worlds) from the NeosVR API
  # Note: API is currently broken but indexer is ready for when it comes back online
  class NeosIndexer < BaseIndexer
    API_BASE_URL = "https://api.neos.com".freeze
    SESSIONS_ENDPOINT = "#{API_BASE_URL}/api/sessions".freeze

    def requires_robots_txt_check?
      false # NeosVR API has no robots.txt file
    end

    def fetch_items
      log_info "Fetching public sessions from NeosVR API"

      # Don't cache API requests - we want fresh session data
      max_items = config.fetch("max_items") { 100 }

      begin
        # Fetch public sessions using the API
        response = make_request("#{SESSIONS_ENDPOINT}?accessLevel=Anyone")

        unless response.success?
          log_warn "NeosVR API returned HTTP #{response.code}"
          return []
        end

        # Parse JSON response
        parsed_response = response.parsed_response

        unless parsed_response.is_a?(Array)
          log_warn "NeosVR API returned unexpected format: expected array, got #{parsed_response.class}"
          return []
        end

        # Limit to max_items for performance
        limited_sessions = parsed_response.first(max_items)
        log_info "Found #{parsed_response.size} total sessions, processing first #{limited_sessions.size}"

        # Convert API response to our internal format
        sessions = limited_sessions.map do |session_data|
          extract_session_info(session_data)
        end.compact

        log_info "Successfully processed #{sessions.size} sessions from NeosVR API"
        sessions
      rescue JSON::ParserError => e
        log_error "Failed to parse NeosVR API response as JSON: #{e.message}"
        []
      rescue StandardError => e
        # Check if this is the known API outage
        if e.message.include?("404") || e.message.include?("503") || e.message.include?("500")
          log_warn "NeosVR API appears to be down (#{e.message}) - this is a known issue"
          []
        else
          log_error "Failed to fetch from NeosVR API: #{e.message}"
          raise "NeosVR API Error: #{e.message}"
        end
      end
    end

    def process_item(session_data)
      log_debug "Processing session: #{session_data[:name]} (#{session_data[:session_id]})"

      normalized_data = normalize_content(session_data)

      # Save the indexed content
      indexed_content = save_indexed_content(normalized_data)

      if indexed_content
        log_debug "Successfully processed session: #{session_data[:name]}"
        update_progress(1) if respond_to?(:update_progress)
      elsif respond_to?(:handle_item_error)
        handle_item_error(StandardError.new("Failed to save indexed content"), session_data)
      end

      indexed_content
    end

    protected

    def extract_session_info(session_api_data)
      # Extract session information from NeosVR API response
      # Based on the SessionInfo schema from the OpenAPI spec
      {
        session_id: session_api_data["sessionId"] || session_api_data["id"],
        name: session_api_data["name"] || "Unnamed Session",
        description: session_api_data["description"],
        host_username: session_api_data["hostUsername"],
        host_user_id: session_api_data["hostUserId"],
        max_users: session_api_data["maxUsers"],
        active_users: session_api_data["activeUsers"],
        access_level: session_api_data["accessLevel"],
        has_ended: session_api_data["hasEnded"],
        is_valid: session_api_data["isValid"],
        universe_id: session_api_data["universeId"],
        app_version: session_api_data["appVersion"],
        headless_host: session_api_data["headlessHost"],
        compatible_version: session_api_data["compatibleVersion"],
        session_url: build_session_url(session_api_data),
        thumbnail: session_api_data["thumbnail"],
        tags: session_api_data["tags"] || [],
        session_users: session_api_data["sessionUsers"] || [],
        raw_session_data: session_api_data
      }
    end

    def build_session_url(session_data)
      # Build a NeosVR session URL if we have the session ID
      session_id = session_data["sessionId"] || session_data["id"]
      session_id ? "neos:///sessions/#{session_id}" : nil
    end

    def extract_external_id(raw_data)
      raw_data[:session_id] || raw_data[:name] || "unknown"
    end

    def extract_content_type(_raw_data)
      "session" # NeosVR sessions are worlds/sessions
    end

    def extract_title(raw_data)
      raw_data[:name] || "Unnamed NeosVR Session"
    end

    def extract_description(raw_data)
      description = raw_data[:description]
      return description if description.present?

      # Generate description from session metadata
      user_info = ""
      user_info = " (#{raw_data[:active_users]}/#{raw_data[:max_users]} users)" if raw_data[:active_users] && raw_data[:max_users]

      host_info = ""
      host_info = " hosted by #{raw_data[:host_username]}" if raw_data[:host_username]

      "NeosVR session#{user_info}#{host_info}"
    end

    def extract_author(raw_data)
      raw_data[:host_username]
    end

    def extract_coordinates(_raw_data)
      # NeosVR doesn't use spatial coordinates like Decentraland
      nil
    end

    def extract_metadata(raw_data)
      {
        session_id: raw_data[:session_id],
        access_level: raw_data[:access_level],
        max_users: raw_data[:max_users],
        active_users: raw_data[:active_users],
        host_user_id: raw_data[:host_user_id],
        universe_id: raw_data[:universe_id],
        app_version: raw_data[:app_version],
        headless_host: raw_data[:headless_host],
        compatible_version: raw_data[:compatible_version],
        has_ended: raw_data[:has_ended],
        is_valid: raw_data[:is_valid],
        session_url: raw_data[:session_url],
        thumbnail: raw_data[:thumbnail],
        tags: raw_data[:tags],
        session_users_count: raw_data[:session_users]&.size || 0,
        indexed_at: Time.current.iso8601
      }.compact
    end
  end
end
