#!/usr/bin/env ruby
# frozen_string_literal: true

# Falcon configuration for Libreverse Rails application
# This file configures the Falcon webserver for production deployment

require 'falcon'
require 'falcon/rails'

module Falcon
  module Configuration
    class Libreverse < Falcon::Rails::Configuration
      def initialize
        super
        
        # Application-specific configuration
        @hostname = ENV.fetch('HOSTNAME', 'localhost')
        @port = ENV.fetch('PORT', 3000).to_i
        @environment = ENV.fetch('RAILS_ENV', 'production')
        
        # Performance tuning
        @worker_processes = ENV.fetch('WEB_CONCURRENCY', 4).to_i
        @timeout = ENV.fetch('TIMEOUT', 60).to_i
        
        # SSL configuration (if certificates are available)
        @ssl_enabled = ENV.fetch('SSL_ENABLED', 'false') == 'true'
        @ssl_cert_path = ENV.fetch('SSL_CERT_PATH', nil)
        @ssl_key_path = ENV.fetch('SSL_KEY_PATH', nil)
      end
      
      def endpoints
        if @ssl_enabled && @ssl_cert_path && @ssl_key_path
          [
            Falcon::SecureEndpoint.new(
              host: @hostname,
              port: @port,
              certificate_path: @ssl_cert_path,
              private_key_path: @ssl_key_path
            )
          ]
        else
          [
            Falcon::Endpoint.new(
              host: @hostname,
              port: @port
            )
          ]
        end
      end
      
      def container
        Falcon::Container.new(
          concurrency: @worker_processes,
          timeout: @timeout
        )
      end
    end
  end
end
