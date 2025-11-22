# frozen_string_literal: true
# shareable_constant_value: literal

# ProxyController handles proxying of external analytics scripts
# This allows us to serve analytics scripts from our own domain
# improving privacy, performance, and avoiding ad blockers
class ProxyController < ApplicationController
  # Skip CSRF protection for proxy endpoints since they don't modify data
  skip_before_action :verify_authenticity_token, only: %i[umami_script userscript]

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

  # Proxy userscripts by name
  # GET /proxy/userscripts/:name.js
  def userscript
      name = params[:name]

      # Load userscript URLs from config
      userscript_config = YAML.load_file(Rails.root.join("config/userscripts.yaml"))
      urls = userscript_config["urls"] || []

      # Find the URL that matches the name
      script_url = find_userscript_url(urls, name)

      unless script_url
        head :not_found
        return
      end

      # Fetch the userscript
      script_response = fetch_userscript(script_url)

      # Set appropriate headers
      response.headers["Content-Type"] = "application/javascript; charset=utf-8"
      response.headers["Cache-Control"] = "public, max-age=86400" # Cache for 24 hours
      response.headers["X-Content-Type-Options"] = "nosniff"

      render plain: script_response.body, status: script_response.code
  rescue StandardError => e
      # Log error and return 404
      Rails.logger.error "Failed to proxy userscript #{params[:name]}: #{e.message}"
      head :not_found
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

  def find_userscript_url(urls, name)
    urls.find do |url|
      # Extract name from URL like "adguard-extra" from ".../adguard-extra.user.js"
      url.match?(%r{/#{Regexp.escape(name)}\.user\.js$})
    end
  end

  def fetch_userscript(url)
    HTTParty.get(url,
                 timeout: 30,
                 open_timeout: 10,
                 headers: {
                   "User-Agent" => "LibreverseProxy/1.0"
                 })
  end
end
