# frozen_string_literal: true

# ActivityPub extensions for Libreverse-specific metadata
module LibreverseActivityPub
  NAMESPACE = "https://libreverse.org/ns#"

  CUSTOM_FIELDS = {
    "experienceType" => "#{NAMESPACE}experienceType",
    "author" => "#{NAMESPACE}author",
    "approved" => "#{NAMESPACE}approved",
    "htmlContent" => "#{NAMESPACE}htmlContent",
    "searchVector" => "#{NAMESPACE}searchVector",
    "moderationStatus" => "#{NAMESPACE}moderationStatus",
    "interactionCapabilities" => "#{NAMESPACE}interactionCapabilities",
    "instanceDomain" => "#{NAMESPACE}instanceDomain",
    "creatorAccount" => "#{NAMESPACE}creatorAccount",
    "tags" => "#{NAMESPACE}tags"
  }.freeze
end

# Configure Federails with Libreverse-specific settings
Federails.configure do |config|
  # Use instance domain from application config
  if Rails.application.config.x.instance_domain.include?(":")
    host, port = Rails.application.config.x.instance_domain.split(":")
    config.site_host = host
    config.site_port = port.to_i
  else
    config.site_host = Rails.application.config.x.instance_domain
    config.site_port = Rails.env.production? ? 443 : 3000
  end

  # App identification
  config.app_name = "Libreverse"
  config.app_version = "1.0.0"

  # Enable features
  config.enable_discovery = true
  config.open_registrations = true

  # Force SSL in production
  config.force_ssl = Rails.env.production?
end
