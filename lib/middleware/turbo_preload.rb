# frozen_string_literal: true

require "nokogiri"
require "digest/sha1"

class TurboPreload
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Only process HTML responses
    return [ status, headers, response ] unless html_response?(headers)

    # Handle different response types (ActionController::Live, Rack::BodyProxy, etc.)
    response_body = extract_response_body(response)
    return [ status, headers, response ] if response_body.empty?

    # Caching: Use Rails.cache to store processed HTML based on SHA1 hash of original
    # This saves unnecessary work for repeated identical responses (e.g., static pages)
    if response_body.empty?
      modified_body = response_body
    else
      cache_key = "tp_html:#{::Digest::SHA1.hexdigest(response_body)}"
      modified_body = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        add_turbo_preload(response_body)
      end
    end

    # Update Content-Length header if necessary
    headers["Content-Length"] = modified_body.bytesize.to_s if headers["Content-Length"]

    [ status, headers, [ modified_body ] ]
  end

  private

  def html_response?(headers)
    headers["Content-Type"]&.include?("text/html")
  end

  def extract_response_body(response)
    # Handle Rails response types (e.g., Array, Rack::BodyProxy, ActionController::Live)
    if response.is_a?(Array)
      response.join
    elsif response.respond_to?(:body)
      response.body
    elsif response.respond_to?(:each)
      response.to_a.join
    else
      ""
    end
  end

  def add_turbo_preload(body)
    # Parse HTML with Nokogiri
    doc = Nokogiri::HTML(body)

    # Skip if no HTML document (e.g., partial fragments)
    return body unless doc.html?

    # Select all <a> tags and add data-turbo-preload
    doc.css("a[href]").each do |link|
      href = link["href"].to_s

      # Skip external links, non-HTTP links, and dynamic routes
      next unless href.start_with?("/")
      next if dynamic_route?(href)

      # Add data-turbo-preload unless already present
      link["data-turbo-preload"] = "" unless link["data-turbo-preload"]
    end

    doc.to_html
  end

  def dynamic_route?(href)
    # Customize this to match your dynamic routes (e.g., user-specific, carts, etc.)
    %w[/cart /login /profile /checkout /api].any? { |pattern| href.match?(pattern) }
  end
end
