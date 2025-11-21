# frozen_string_literal: true
# shareable_constant_value: literal

module Metaverse
  # Indexer for Spatial.io metaverse content
  # Fetches space data directly from the Spatial.io sitemap
  class SpatialIndexer < BaseIndexer
    SITEMAP_URL = "https://www.spatial.io/root.xml"

    # Spatial.io doesn't have a robots.txt file, so skip robots.txt checking
    def requires_robots_txt_check?
      false
    end

    def fetch_items
      log_info "Fetching space data from Spatial.io sitemap"

      # Don't cache sitemap requests - we want fresh data for each indexing run
      max_items = config.fetch("max_items") { 100 }

      # Fetch the sitemap using BaseIndexer's make_request for proper rate limiting
      response = make_request(SITEMAP_URL)

      # Parse XML and extract space URLs
      doc = Nokogiri::XML(response.body)
      doc.remove_namespaces! # Remove namespaces for simpler XPath

      # Find all URLs that contain '/s/' (space URLs)
      space_urls = doc.xpath("//url/loc").map(&:text).select { |url| url.include?("/s/") }

      log_info "Found #{space_urls.size} space URLs in sitemap"

      # Limit to max_items
      limited_urls = space_urls.first(max_items)
      log_info "Processing first #{limited_urls.size} spaces"

      # Convert URLs to space data
      spaces = limited_urls.map do |url|
        extract_space_info_from_url(url)
      end.compact

      log_info "Successfully processed #{spaces.size} spaces from sitemap"
      spaces
    rescue StandardError => e
      log_error "Failed to fetch from Spatial.io sitemap: #{e.message}"
      raise "Spatial.io Sitemap Error: #{e.message}"
    end

    def process_item(space_data)
      log_debug "Processing space: #{space_data[:title]} (#{space_data[:external_id]})"

      space_data
    end

    protected

    # Override robots.txt checking for Spatial.io since they don't have robots.txt
    # Sitemaps are specifically meant to be crawled, so this is acceptable
    def robots_allowed?(url)
      uri = URI.parse(url)
      if [ "www.spatial.io", "spatial.io" ].include?(uri.host)
        log_debug "Spatial.io has no robots.txt - allowing sitemap access"
        return true
      end

      # Fall back to default behavior for other domains
      super
    end

    def extract_external_id(raw_data)
      # Extract space ID from URL: /s/space-name-1234567890abcdef -> 1234567890abcdef
      url = raw_data[:url] || ""
      space_id = url.split("-").last if url.include?("/s/")
      space_id || raw_data[:id] || url
    end

    def extract_content_type(_raw_data)
      "space"
    end

    def extract_title(raw_data)
      raw_data[:title] || "Spatial Space"
    end

    def extract_description(raw_data)
      raw_data[:description] || "A virtual space on Spatial.io"
    end

    def extract_author(raw_data)
      raw_data[:creator]
    end

    def extract_coordinates(_raw_data)
      nil # Spatial.io doesn't use coordinate system
    end

    def extract_metadata(raw_data)
      {
        source_url: raw_data[:url],
        space_id: raw_data[:external_id],
        space_name: raw_data[:space_name],
        indexed_at: Time.current.iso8601
      }
    end

    private

    def extract_space_info_from_url(space_url)
      # Extract space name and ID from URL pattern: /s/space-name-space_id
      # Handle query parameters by removing them first
      clean_url = space_url.split("?").first
      match = clean_url.match(%r{/s/(.+)-([a-f0-9]+)$})
      return nil unless match

      space_name = match[1]
      space_id = match[2]

      {
        external_id: space_id,
        title: space_name.tr("-", " ").titleize,
        url: space_url,
        space_name: space_name,
        space_id: space_id,
        description: "A virtual space on Spatial.io: #{space_name.tr('-', ' ').titleize}"
      }
    end
  end
end
