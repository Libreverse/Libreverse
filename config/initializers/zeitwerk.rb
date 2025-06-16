# frozen_string_literal: true

# Ignore the gRPC directory from Zeitwerk autoloading
# This prevents autoloading issues with generated protobuf files
Rails.autoloaders.main.ignore(Rails.root.join("app/grpc"))
