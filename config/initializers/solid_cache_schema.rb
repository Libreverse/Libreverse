# frozen_string_literal: true

return unless defined?(SolidCache::Entry)

begin
  require "solid_cache"
rescue LoadError
  Rails.logger.debug("[Boot] SolidCache gem not available, skipping cache schema check")
  return
end

cache_conn = SolidCache::Entry.connection
unless cache_conn.data_source_exists?("solid_cache_entries")
  schema_file = Rails.root.join("db/cache_schema.rb")

  if File.exist?(schema_file)
    Rails.logger.info("[Boot] Loading Solid Cache schema from #{schema_file}…")
    # Evaluate schema within connection context
    cache_conn.instance_eval(File.read(schema_file))
  else
    Rails.logger.warn("[Boot] cache_schema.rb not found – Solid Cache tables may be missing.")
  end
end
