# frozen_string_literal: true

require "redis-client"

# Ensure the extension directory is on the load path when loading from a vendored path
ext_dir = File.expand_path("../../ext/redis_client/hiredis", __FILE__)
$LOAD_PATH.unshift(ext_dir) unless $LOAD_PATH.include?(ext_dir)

# Load native extension; if missing, try to build it (for vendored path gems)
begin
  require "redis_client/hiredis_connection"
rescue LoadError => e
  # Only attempt build if this looks like a vendored gem (ext directory exists)
  if File.exist?(File.join(ext_dir, "extconf.rb"))
    begin
      require "mkmf"
      Dir.chdir(ext_dir) do
        # Generate Makefile and build the extension
        system(RbConfig.ruby, "extconf.rb") || raise("extconf.rb failed")
        system(ENV["MAKE"] || "make") || raise("make failed")
      end
      # Retry loading
      require "redis_client/hiredis_connection"
    rescue StandardError => build_err
      raise LoadError, "hiredis-client: failed to load native extension.\n" \
                       "Original: #{e.message}\n" \
                       "Build error: #{build_err.message}\n" \
                       "Ensure build tools are installed."
    end
  else
    # Not a vendored gem, re-raise original error
    raise
  end
end

RedisClient.register_driver(:hiredis) { RedisClient::HiredisConnection }
RedisClient.default_driver = :hiredis
