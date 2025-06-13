# frozen_string_literal: true

# Federails Configuration
# Consolidated federation configuration in the initializer instead of YAML

Federails.configure do |config|
  # Application identity
  config.app_name = "Libreverse"
  config.app_version = "1.0.0"

  # SSL and domain configuration
  if Rails.env.production?
    config.force_ssl = true
    config.site_host = "https://#{Rails.application.config.x.instance_domain}"
    config.site_port = 3000
  elsif Rails.env.test?
    config.force_ssl = false
    config.site_host = "http://localhost"
    config.site_port = nil # No port for test
  else # development
    config.force_ssl = false
    config.site_host = "http://localhost"
    config.site_port = 3000
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
