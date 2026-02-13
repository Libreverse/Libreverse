# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# AnyCable configuration
Rails.application.configure do
  # Use AnyCable as the Action Cable adapter
  config.action_cable.adapter = :anycable

  # Configure AnyCable RPC server (default: localhost:50051)
  # Set via ANYCABLE_RPC_HOST environment variable in production
  config.x.anycable_rpc_host = ENV.fetch("ANYCABLE_RPC_HOST") { "localhost:50051" }

  # Enable HTTP pub/sub fallback for development
  config.anycable_http_pubsub_url = ENV.fetch("ANYCABLE_HTTP_PUBSUB_URL") { nil }
end
