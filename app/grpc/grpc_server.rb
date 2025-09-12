# frozen_string_literal: true

require "grpc"
require_relative "libreverse_service"

module Libreverse
  # Main gRPC server class
  class GrpcServer
    def initialize
      @server = GRPC::RpcServer.new
    end

    def start(port = nil)
      # Respect dynamic instance setting for gRPC enablement
      begin
        unless LibreverseInstance::Application.grpc_enabled?
          Rails.logger.info "gRPC is disabled by instance setting; skipping server startup"
          return
        end
      rescue StandardError => e
        Rails.logger.warn "Unable to check gRPC enablement, proceeding: #{e.message}"
      end

      port ||= GrpcConfig.port
      bind_address = "#{GrpcConfig.host}:#{port}"
      credentials = GrpcConfig.ssl_credentials

      # Determine credentials; if nil, gRPC is disabled
      if credentials.nil?
        Rails.logger.warn "gRPC credentials unavailable; skipping server startup"
        return
      end

      # Add the service handler
      @server.add_http2_port(bind_address, credentials)
      @server.handle(Libreverse::Grpc::LibreverseServiceImpl.new)

      # Setup signal handlers for graceful shutdown
      setup_signal_handlers

      Rails.logger.info "Starting gRPC server on #{bind_address}"
      Rails.logger.info "SSL: #{credentials == :this_port_is_insecure ? 'disabled' : 'enabled'}"
      begin
        @server.run_till_terminated_or_interrupted([ 1, "int", "SIGTERM" ])
      rescue StandardError => e
        Rails.logger.error "gRPC server crashed: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") if e.backtrace
      end
    end

    def stop
      @server&.stop
    end

    private

    def setup_signal_handlers
      %w[INT TERM].each do |signal|
        Signal.trap(signal) do
          Rails.logger.info "Received #{signal}, shutting down gRPC server gracefully"
          @server&.stop

          # Only exit if we're running as a standalone process (not integrated)
          if ENV["GRPC_INTEGRATED"] != "true" && Rails.application.respond_to?(:stop)
            # Use Rails.application.stop instead of Kernel.exit in Rails applications
            Rails.application.stop
          end
        end
      end
    end
  end
end
