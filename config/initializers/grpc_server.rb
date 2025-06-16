# frozen_string_literal: true

# gRPC Server Integration for Rails
# This initializer starts the gRPC server within the main Rails process

Rails.application.configure do
    # Start gRPC server in a background thread after Rails boots
    config.after_initialize do
      Thread.new do
          Rails.logger.info "Starting integrated gRPC server..."

          # Load gRPC dependencies
          require Rails.root.join("app/grpc/grpc_server")

          # Start the gRPC server
          server = Libreverse::GrpcServer.new
          server.start
      rescue StandardError => e
          Rails.logger.error "Failed to start integrated gRPC server: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
      end
    end
end
