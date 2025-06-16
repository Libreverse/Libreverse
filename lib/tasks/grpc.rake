# frozen_string_literal: true

namespace :grpc do
  desc "Generate gRPC service files from protobuf definitions"
  task generate: :environment do
    proto_dir = Rails.root.join("lib/grpc")
    output_dir = Rails.root.join("app/grpc")

    # Ensure output directory exists
    FileUtils.mkdir_p(output_dir)

    # Generate Ruby files from proto
    ok = system("grpc_tools_ruby_protoc -I #{proto_dir} --ruby_out=#{output_dir} --grpc_out=#{output_dir} #{proto_dir}/libreverse.proto")
    abort("protoc failed – see above") unless ok
    puts "gRPC service files generated in #{output_dir}"
  end

  desc "Start gRPC server"
  task server: :environment do
    require_relative "../../app/grpc/grpc_server"

    port = ENV.fetch("GRPC_PORT", "50051")
    puts "Starting gRPC server on port #{port}"

    server = Libreverse::GrpcServer.new
    server.start(port)
  end
end
