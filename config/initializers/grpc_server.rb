# frozen_string_literal: true

# gRPC Server Integration for Rails
# This initializer starts the gRPC server within the main Rails process

Rails.application.configure do
    # Start gRPC server in a background thread after Rails boots
    config.after_initialize do
        # Check if gRPC is enabled before attempting to start
        unless LibreverseInstance::Application.grpc_enabled?
            Rails.logger.info "gRPC server is disabled - skipping startup"
            next
        end

        Thread.new do
            Thread.current.abort_on_exception = true
            Thread.current.name = "grpc-server" if Thread.current.respond_to?(:name=)
            Rails.logger.info "Starting integrated gRPC server..."

            begin
                require Rails.root.join("app/grpc/grpc_server")
                server = Libreverse::GrpcServer.new
                server.start
            rescue StandardError => e
                Rails.logger.error "Failed to start integrated gRPC server: #{e.message}"
                Rails.logger.error e.backtrace.join("\n")
            end
        end
    end
end
