# frozen_string_literal: true

# gRPC Configuration for Libreverse
module Libreverse
  module GrpcConfig
    # Default gRPC server port
    DEFAULT_PORT = 50_051

    # gRPC server options (note: newer gRPC versions configure these differently)
    # SERVER_OPTIONS = {
    #   pool_size: 30,
    #   max_waiting_requests: 20,
    #   poll_period: 1
    # }.freeze

    # Rate limiting for gRPC endpoints (requests per minute)
    RATE_LIMIT = 30

    # Maximum request size (in bytes)
    MAX_REQUEST_SIZE = 1 * 1024 * 1024

    # Request timeout (in seconds)
    REQUEST_TIMEOUT = 30

    class << self
      def port
        ENV.fetch("GRPC_PORT") { DEFAULT_PORT }.to_i
      end

      def host
        ENV.fetch("GRPC_HOST") { "0.0.0.0" }
      end

      def bind_address
        "#{host}:#{port}"
      end

      def ssl_credentials
        if Rails.env.production?
          # In production, use proper SSL credentials
          ssl_cert = ENV["GRPC_SSL_CERT_PATH"]
          ssl_key = ENV["GRPC_SSL_KEY_PATH"]

          if ssl_cert && ssl_key && File.exist?(ssl_cert) && File.exist?(ssl_key)
            cert_chain = File.read(ssl_cert)
            private_key = File.read(ssl_key)
            GRPC::Core::ServerCredentials.new(nil, [ { private_key: private_key, cert_chain: cert_chain } ], false)
          else
            msg = "gRPC SSL cert/key missing – aborting startup (set GRPC_ALLOW_INSECURE=true to override)"
            raise msg unless ENV["GRPC_ALLOW_INSECURE"] == "true"

              Rails.logger.error "#{msg} (CONTINUING WITH INSECURE CHANNEL)"
              :this_port_is_insecure

          end
        else
          # In development/test, use insecure connection
          :this_port_is_insecure
        end
      end
    end
  end
end

# Configure gRPC logging
if defined?(GRPC)
  GRPC.logger = Rails.logger
  GRPC.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
end
