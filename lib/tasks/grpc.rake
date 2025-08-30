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
end
