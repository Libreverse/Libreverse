# frozen_string_literal: true

class RobotsController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /robots.txt
  def show
    content = if no_bots_mode_enabled?
      # Disallow all bots when no_bots_mode is enabled
      <<~TXT
        User-agent: *
        Disallow: /
      TXT
    else
      # Default robots.txt - allow all
      <<~TXT
        User-agent: *
        Disallow:
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