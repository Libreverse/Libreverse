# frozen_string_literal: true

# ProxyController handles proxying of external analytics scripts
# This allows us to serve analytics scripts from our own domain
# improving privacy, performance, and avoiding ad blockers
class ProxyController < ApplicationController
  # Skip CSRF protection for proxy endpoints since they don't modify data
  skip_before_action :verify_authenticity_token, only: [ :umami_script ]

  # Proxy the Umami analytics script
  # GET /umami/script.js
  def umami_script
    # Only serve in production to avoid analytics in development/test
    unless Rails.env.production?
      head :not_found
      return
    end

    begin
      # Fetch the script from Umami Cloud
      umami_response = fetch_umami_script

      # Set appropriate headers and render the script
      response.headers["Content-Type"] = "application/javascript; charset=utf-8"
      response.headers["Cache-Control"] = "public, max-age=86400" # Cache for 24 hours
      response.headers["X-Content-Type-Options"] = "nosniff"

      render plain: umami_response.body, status: umami_response.code
    rescue StandardError => e
      # Log error and return 404 to avoid breaking the page
      Rails.logger.error "Failed to proxy Umami script: #{e.message}"
      head :not_found
    end
  end

  private

  def fetch_umami_script
    HTTParty.get("https://cloud.umami.is/script.js",
                 timeout: 10,
                 open_timeout: 5,
                 headers: {
                   "User-Agent" => "LibreverseProxy/1.0"
                 })
  end
end
