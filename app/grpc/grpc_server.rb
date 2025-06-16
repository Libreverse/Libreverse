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
      port ||= GrpcConfig.port
      bind_address = "#{GrpcConfig.host}:#{port}"
      credentials = GrpcConfig.ssl_credentials

      # Add the service handler
      @server.add_http2_port(bind_address, credentials)
      @server.handle(Libreverse::Grpc::LibreverseServiceImpl.new)

      # Setup signal handlers for graceful shutdown
      setup_signal_handlers

      Rails.logger.info "Starting gRPC server on #{bind_address}"
      Rails.logger.info "SSL: #{credentials == :this_port_is_insecure ? 'disabled' : 'enabled'}"
      @server.run_till_terminated_or_interrupted([ 1, "int", "SIGTERM" ])
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
