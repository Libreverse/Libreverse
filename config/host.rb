#!/usr/bin/env ruby
# frozen_string_literal: true

# Falcon host configuration for production deployment
# This file defines the services and endpoints for Falcon host

require 'falcon'
require 'falcon/rails'

# Configure the Rails application
Rails.application.eager_load!

# Create the service configuration
service = Falcon::Service::Rails.new(
  Rails.application,
  environment: ENV.fetch('RAILS_ENV', 'production'),
  timeout: ENV.fetch('TIMEOUT', 60).to_i
)

# Configure endpoints based on environment
if ENV.fetch('SSL_ENABLED', 'false') == 'true' && 
   ENV['SSL_CERT_PATH'] && ENV['SSL_KEY_PATH']
  
  # HTTPS endpoint with SSL
  endpoint = Falcon::SecureEndpoint.new(
    host: ENV.fetch('HOSTNAME', '0.0.0.0'),
    port: ENV.fetch('PORT', 443).to_i,
    certificate_path: ENV.fetch('SSL_CERT_PATH'),
    private_key_path: ENV.fetch('SSL_KEY_PATH')
  )
  
  # Redirect HTTP to HTTPS
  redirect_endpoint = Falcon::Endpoint.new(
    host: ENV.fetch('HOSTNAME', '0.0.0.0'),
    port: 80
  )
  
  services = [
    Falcon::RedirectService.new(redirect_endpoint, "https://#{ENV.fetch('HOSTNAME', 'localhost')}:#{ENV.fetch('PORT', 443)}"),
    service
  ]
  
  endpoints = [redirect_endpoint, endpoint]
else
  # HTTP endpoint only
  endpoint = Falcon::Endpoint.new(
    host: ENV.fetch('HOSTNAME', '0.0.0.0'),
    port: ENV.fetch('PORT', 3000).to_i
  )
  
  services = [service]
  endpoints = [endpoint]
end

# Create the host configuration
host = Falcon::Host.new(
  services: services,
  endpoints: endpoints,
  container: Falcon::Container.new(
    concurrency: ENV.fetch('WEB_CONCURRENCY', 4).to_i,
    timeout: ENV.fetch('TIMEOUT', 60).to_i
  )
)

# Run the host
host.run
