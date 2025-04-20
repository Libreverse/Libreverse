# frozen_string_literal: true

begin
  require "solid_cable/message"
rescue LoadError
  # SolidCable not loaded; skip schema check
  Rails.logger.debug("[Boot] SolidCable gem not available, skipping cable schema check")
  return
end

message_conn = SolidCable::Message.connection
unless message_conn.data_source_exists?("solid_cable_messages")
  schema_file = Rails.root.join("db/cable_schema.rb")

  if File.exist?(schema_file)
    Rails.logger.info("[Boot] Loading Solid Cable schema from #{schema_file}…")
    message_conn.instance_eval(File.read(schema_file))
  else
    Rails.logger.warn("[Boot] cable_schema.rb not found – Solid Cable tables may be missing.")
  end
end
