# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Service to fetch CSS from Vite development server
class ViteDevCssFetcher
  include Singleton

  def initialize
    @timeout = 5
    @base_url = "http://#{ViteRuby.config.host}:#{ViteRuby.config.port}"
  end

  # Fetch CSS content from Vite dev server
  def fetch_css(css_path)
    return nil unless Rails.env.development?
    return nil unless dev_server_running?

    normalized_path = normalize_css_path(css_path)
    url = "#{@base_url}/#{normalized_path}"

    Rails.logger.debug "[ViteDevCssFetcher] Fetching CSS from: #{url}"

    response = fetch_with_timeout(url)
    if response.code >= 200 && response.code < 300
      process_css_response(response.body)
    else
      Rails.logger.warn "[ViteDevCssFetcher] Failed to fetch CSS: #{response&.code}"
      nil
    end
  rescue StandardError => e
    Rails.logger.warn "[ViteDevCssFetcher] Error fetching CSS: #{e.message}"
    nil
  end

  # Check if Vite dev server is running
  def dev_server_running?
    return @dev_server_running if defined?(@dev_server_running)

    @dev_server_running = check_server_status
  end

  # Force check server status (bypass cache)
  def dev_server_running!
    @server_status = check_server_status
  end

  private

  def normalize_css_path(css_path)
    # Remove leading ~/ if present
    path = css_path.sub(%r{^~/}, "")

    # Convert .scss to .css for dev server
    path = path.sub(/\.scss$/, ".css")

    # Ensure stylesheets prefix if not present
    path = "stylesheets/#{path}" if !path.start_with?("stylesheets/") && !path.include?("/")

    path
  end

  def fetch_with_timeout(url)
    HTTParty.get(url,
                 timeout: @timeout,
                 open_timeout: @timeout,
                 headers: {
                   "Accept" => "text/css",
                   "User-Agent" => "LibreVerse-Email-Inliner"
                 })
  end

  def process_css_response(css_content)
    return nil if css_content.blank?

    # Basic CSS processing
    processed = css_content.strip

    # Remove source maps - fixed regex to prevent ReDoS
    processed = processed.gsub(%r{/\*# sourceMappingURL=[^*]*\*/}, "")

    # Convert any @import statements to comments (since we're inlining) - fixed regex
    processed = processed.gsub(/@import[^;]{1,200};/, "/* @import removed for email inlining */")

    # Compress whitespace but keep readability - fixed to prevent ReDoS
    processed.gsub(/\s+\{/, " {")
             .gsub(/\}\s+/, "} ")
             .gsub(/;\s+/, "; ")
             .gsub(/,\s+/, ", ")
  end

  def check_server_status
      response = HTTParty.get("http://#{ViteRuby.config.host}:#{ViteRuby.config.port}/",
                              timeout: 2,
                              open_timeout: 2)

      # Vite dev server should respond with some form of success
      response.code >= 200 && response.code < 400
  rescue StandardError => e
      Rails.logger.debug "[ViteDevCssFetcher] Dev server check failed: #{e.message}"
      false
  end
end
