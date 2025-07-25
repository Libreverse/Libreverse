# frozen_string_literal: true

class RobotsController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /robots.txt
  def show
    # Turbocache-optimized headers for robots.txt
    set_turbocache_headers(duration: 2.seconds, must_revalidate: true)

    # Also set longer browser cache as fallback
    cache_control = response.headers["Cache-Control"]
    if cache_control.present?
      response.headers["Cache-Control"] += ", stale-while-revalidate=3600"
    else
      # In test/development environment, set basic cache headers
      response.headers["Cache-Control"] = "public, max-age=2, stale-while-revalidate=3600"
    end

    # Set Last-Modified header based on instance settings
    last_modified_time = InstanceSetting.maximum(:updated_at) || 1.day.ago
    check_last_modified(last_modified_time)

    content = if no_bots_mode_enabled?
      # Disallow all bots when no_bots_mode is enabled
      <<~TXT
        User-agent: *
        Disallow: /
      TXT
    else
      # Default robots.txt - allow all
      host = InstanceSetting.get("canonical_host")
host ||= begin
  uri = URI.parse(request.base_url)
  # Allow only well-formed http(s) schemes and strip user-info, port, etc.
  %w[http https].include?(uri.scheme) ? "#{uri.scheme}://#{uri.host}" : ""
end
      <<~TXT
        User-agent: *
        Disallow:

        Sitemap: #{host}/sitemap.xml
      TXT
    end

    render plain: content, content_type: "text/plain"
  end

  private

  def no_bots_mode_enabled?
    setting_value = InstanceSetting.get("no_bots_mode")
    setting_value.to_s.downcase.in?(%w[true 1 yes on enabled])
  rescue StandardError => e
    Rails.logger.error "[RobotsController] Error checking no_bots_mode setting: #{e.message}"
    false # Default to allowing bots if we can't check the setting
  end
end
