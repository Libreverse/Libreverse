# frozen_string_literal: true

class RobotsController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /robots.txt
  def show
    # Set cache headers - robots.txt changes infrequently
    # Skip cache headers in development to avoid masking application errors
    expires_in 1.day, public: true unless Rails.env.development?

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
