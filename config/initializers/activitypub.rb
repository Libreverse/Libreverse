# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Federails Configuration
# Consolidated federation configuration in the initializer instead of YAML

Federails.configure do |config|
  # Application identity
  config.app_name = "Libreverse"
  config.app_version = "1.0.0"

  # Get instance domain from the centralized configuration system
  # Use LibreverseInstance.instance_domain which handles environment detection and fallbacks
  instance_domain = LibreverseInstance.instance_domain
  raise "Missing instance domain – required for Federails initialisation" if instance_domain.blank?

  raise "Missing instance domain configuration – required for Federails initialisation" if instance_domain.blank?

  # SSL and domain configuration
  if Rails.env.production?
    config.force_ssl = true
    if instance_domain.include?(":")
      host, port = instance_domain.split(":", 2)
      config.site_host = "https://#{host}"
      config.site_port = port.to_i
    else
      config.site_host = "https://#{instance_domain}"
      config.site_port = 443
    end
  elsif Rails.env.test?
    config.force_ssl = false
    config.site_host = "http://localhost"
    config.site_port = nil # No port for test
  else # development
    config.force_ssl = false
    if instance_domain.include?(":")
      host, port = instance_domain.split(":", 2)
      config.site_host = "http://#{host}"
      config.site_port = port.to_i
    else
      config.site_host = "http://#{instance_domain}"
      config.site_port = 3000
    end
  end

  # Federation features
  config.enable_discovery = true
  config.open_registrations = true

  # UI and routing
  config.app_layout = "layouts/application"
  config.server_routes_path = "federation"
  config.client_routes_path = "app"

  # Optionally uncomment if you need to customize the base controller
  # config.base_client_controller = ::ActionController::Base
end

# Configure encryption for Federails Actor private keys
Rails.application.config.after_initialize do
  # Extend the Federails::Actor model to encrypt private keys
  if defined?(Federails::Actor)
    Federails::Actor.class_eval do
      encrypts :private_key
    end
  end
end

# Configure Federails moderation for handling reports about federated content
Federails::Moderation.configure do |conf|
  # Handle incoming reports about experiences
  conf.after_report_created = lambda do |report|
    LibreverseReportHandler.new(report).process
  rescue StandardError => e
    Rails.logger.error("LibreverseReportHandler failed: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    # Optionally enqueue a retry job instead of aborting the request thread
    # Libreverse::ReportHandlerJob.perform_later(report.id)
  end
end

# ActivityPub extensions for Libreverse-specific metadata
module LibreverseActivityPub
  NAMESPACE = "https://libreverse.org/ns#"

  CUSTOM_FIELDS = {
    "experienceType" => "#{NAMESPACE}experienceType".freeze,
    "author" => "#{NAMESPACE}author".freeze,
    "approved" => "#{NAMESPACE}approved".freeze,
    "htmlContent" => "#{NAMESPACE}htmlContent".freeze,
    "searchVector" => "#{NAMESPACE}searchVector".freeze,
    "moderationStatus" => "#{NAMESPACE}moderationStatus".freeze,
    "interactionCapabilities" => "#{NAMESPACE}interactionCapabilities".freeze,
    "instanceDomain" => "#{NAMESPACE}instanceDomain".freeze,
    "creatorAccount" => "#{NAMESPACE}creatorAccount".freeze,
    "tags" => "#{NAMESPACE}tags".freeze
  }.freeze
end
